import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../ai/ai_parser.dart';
import '../ai/ai_llm_parser.dart';
import '../providers/app_data_provider.dart';

/// AI 录入浮动按钮
class AiInputButton extends StatelessWidget {
  const AiInputButton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FloatingActionButton.extended(
      onPressed: () => _showInputSheet(context),
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: theme.colorScheme.onPrimary,
      icon: const Icon(Icons.auto_awesome_rounded),
      label: const Text('AI 录入'),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  void _showInputSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AiInputSheet(),
    );
  }
}

/// AI 录入底部弹窗
class _AiInputSheet extends StatefulWidget {
  const _AiInputSheet();

  @override
  State<_AiInputSheet> createState() => _AiInputSheetState();
}

class _AiInputSheetState extends State<_AiInputSheet> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFieldFocus = FocusNode();

  String _currentText = '';
  List<ParsedResult> _parsedResults = [];
  bool _isParsing = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final hasText = _textController.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _textFieldFocus.dispose();
    super.dispose();
  }

  /// 解析文本（使用大模型）
  Future<void> _parseTextAndDismissKeyboard() async {
    // 先收起键盘
    FocusScope.of(context).unfocus();
    // 等待一小段时间让键盘收起
    await Future.delayed(const Duration(milliseconds: 100));
    // 再执行解析
    await _parseText();
  }

  Future<void> _parseText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isParsing = true);

    try {
      final jsonStr = await AiLlmParser.parse(text);

      if (jsonStr.isEmpty) {
        // 大模型调用失败，回退到规则引擎
        debugPrint('🤖 LLM 失败，回退规则引擎');
        final parser = AiParser();
        final results = parser.parseMultiple(text);
        if (mounted) setState(() => _parsedResults = results);
        return;
      }

      // 解析大模型返回的 JSON
      final data = jsonDecode(jsonStr);
      final items = data['items'] as List? ?? [];
      debugPrint('🤖 LLM 解析成功，共 ${items.length} 条');
      final results = <ParsedResult>[];

      for (final item in items) {
        final type = item['type'] as String?;
        if (type == 'expense') {
          results.add(ParsedResult(
            type: ParsedIntent.expense,
            expenseAmount: (item['amount'] as num?)?.toDouble(),
            expenseCategory: item['category'] as String?,
            expenseNote: item['note'] as String?,
            todoDate: item['date'] != null ? DateTime.tryParse(item['date'] as String) : null,
            dateLabel: item['date'] as String?,
            originalText: text,
          ));
        } else if (type == 'todo') {
          results.add(ParsedResult(
            type: ParsedIntent.todo,
            todoContent: item['content'] as String?,
            todoTime: item['time'] != null
                ? _parseTimeOfDay(item['time'] as String)
                : null,
            todoDate: item['date'] != null ? DateTime.tryParse(item['date'] as String) : null,
            dateLabel: item['date'] as String?,
            originalText: text,
          ));
        }
      }

      if (mounted) setState(() => _parsedResults = results);
    } catch (e) {
      debugPrint('🤖 解析异常: $e');
      // 异常时回退规则引擎
      final parser = AiParser();
      final results = parser.parseMultiple(text);
      if (mounted) setState(() => _parsedResults = results);
    } finally {
      if (mounted) setState(() => _isParsing = false);
    }
  }

  TimeOfDay? _parseTimeOfDay(String timeStr) {
    final parts = timeStr.split(':');
    if (parts.length == 2) {
      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      if (h != null && m != null) {
        return TimeOfDay(hour: h, minute: m);
      }
    }
    return null;
  }

  /// 确认结果并保存
  Future<void> _confirmResults() async {
    if (_parsedResults.isEmpty) return;
    final navigator = Navigator.of(context);
    final provider = context.read<AppDataProvider>();

    for (final result in _parsedResults) {
      switch (result.type) {
        case ParsedIntent.expense:
          if (result.expenseAmount != null) {
            await provider.addBill(
              amount: result.expenseAmount!,
              category: result.expenseCategory ?? '其他',
              note: result.expenseNote ?? '',
              date: result.todoDate,
            );
          }
        case ParsedIntent.todo:
          String? timeStr;
          if (result.todoTime != null) {
            timeStr =
                '${result.todoTime!.hour.toString().padLeft(2, '0')}:${result.todoTime!.minute.toString().padLeft(2, '0')}';
          }
          await provider.addTodo(
            content: result.todoContent ?? '',
            time: timeStr,
            date: result.todoDate,
            hasReminder: result.todoTime != null,
          );
        case ParsedIntent.unknown:
          break;
      }
    }

    if (mounted) navigator.pop();
  }

  void _clearAll() {
    setState(() {
      _currentText = '';
      _parsedResults = [];
    });
    _textController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final hasResults = _parsedResults.isNotEmpty;
    final effectiveText = _textController.text;

    return Container(
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),

              // 标题栏
              Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text('智能录入',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface)),
                  const Spacer(),
                  if (effectiveText.isNotEmpty || hasResults)
                    IconButton(
                        icon: const Icon(Icons.refresh, size: 20),
                        onPressed: _clearAll,
                        tooltip: '重置'),
                ],
              ),
              const SizedBox(height: 8),
              Text('输入内容后点击"解析"，支持一次性输入多条',
                  style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),

              const SizedBox(height: 16),

              // 提示词
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline, size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '使用输入法自带的语音转文字更便捷哦',
                        style: TextStyle(fontSize: 13, color: theme.colorScheme.primary),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ===== 输入区域（未解析时显示）=====
              if (!hasResults) ...[
                // 输入框
                TextField(
                  controller: _textController,
                  maxLines: 4,
                  focusNode: _textFieldFocus,
                  decoration: InputDecoration(
                    hintText: '例如：提醒我明天早上八点起床、今天购物花了三十',
                    hintStyle: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                    border:
                        OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
                const SizedBox(height: 16),

                // 解析按钮
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isParsing ? null : (_hasText ? _parseTextAndDismissKeyboard : null),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isParsing
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('🔍 解析'),
                  ),
                ),
              ],

              // ===== 解析结果预览 =====
              if (hasResults) ...[
                const SizedBox(height: 12),
                Text('识别结果（左滑可删除）：',
                    style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _parsedResults.length,
                    itemBuilder: (context, index) {
                      final r = _parsedResults[index];
                      return _ParsedResultCard(
                        result: r,
                        onRemove: () {
                          setState(() => _parsedResults.removeAt(index));
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                // 确认按钮
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _confirmResults,
                    icon: const Icon(Icons.check_circle_outline_rounded),
                    label: Text('确认添加 ${_parsedResults.length} 条记录'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _clearAll,
                  child: const Text('重新输入'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 解析结果卡片
class _ParsedResultCard extends StatelessWidget {
  final ParsedResult result;
  final VoidCallback onRemove;

  const _ParsedResultCard({required this.result, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (result.type == ParsedIntent.expense) {
      final isIncome = (result.expenseAmount ?? 0) >= 0;
      final color = isIncome ? Colors.green : theme.colorScheme.error;
      final sign = isIncome ? '+' : '-';
      final abs = (result.expenseAmount ?? 0).abs();
      final dateInfo = result.dateLabel != null ? ' · ${result.dateLabel}' : '';

      return Dismissible(
        key: ValueKey(result),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onRemove(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 16),
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.close, color: theme.colorScheme.error, size: 20),
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Text('💰', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.expenseNote?.isNotEmpty == true
                          ? result.expenseNote!
                          : result.expenseCategory ?? '其他',
                      style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface),
                    ),
                    Text(
                      '${result.expenseCategory ?? ''}$dateInfo',
                      style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                    ),
                  ],
                ),
              ),
              Text(
                '$sign${abs.toStringAsFixed(2)}',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
        ),
      );
    } else if (result.type == ParsedIntent.todo) {
      final timeStr = result.todoTime != null
          ? ' ${result.todoTime!.hour.toString().padLeft(2, '0')}:${result.todoTime!.minute.toString().padLeft(2, '0')}'
          : '';
      final dateInfo = result.dateLabel != null ? ' · ${result.dateLabel}' : '';

      return Dismissible(
        key: ValueKey(result),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onRemove(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 16),
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.close, color: theme.colorScheme.error, size: 20),
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Text('📋', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${result.todoContent ?? ''}$timeStr$dateInfo',
                  style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}