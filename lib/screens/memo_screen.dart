import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/database.dart';
import '../providers/app_data_provider.dart';
import '../services/password_service.dart';

/// 备忘录页面（需密码解锁）
class MemoScreen extends StatefulWidget {
  const MemoScreen({super.key});

  @override
  State<MemoScreen> createState() => _MemoScreenState();
}

class _MemoScreenState extends State<MemoScreen> {
  bool _isUnlocked = false;
  bool _isLoading = true;
  bool _isFirstTime = false;
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  String _errorText = '';

  @override
  void initState() {
    super.initState();
    _checkFirstTime();
  }

  Future<void> _checkFirstTime() async {
    final firstTime = !(await PasswordService.isPasswordSet());
    if (mounted) {
      setState(() {
        _isFirstTime = firstTime;
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyAndUnlock() async {
    final password = _passwordController.text;
    if (password.isEmpty) return;

    final valid = await PasswordService.verifyPassword(password);
    if (valid) {
      setState(() => _isUnlocked = true);
      _passwordController.clear();
    } else {
      setState(() => _errorText = '密码错误');
    }
  }

  Future<void> _resetPassword() async {
    final newPwd = _newPasswordController.text;
    final confirmPwd = _confirmPasswordController.text;

    if (newPwd.length < 6) {
      setState(() => _errorText = '密码至少6位');
      return;
    }
    if (newPwd != confirmPwd) {
      setState(() => _errorText = '两次密码不一致');
      return;
    }

    await PasswordService.setPassword(newPwd);
    if (mounted) {
      setState(() {
        _isFirstTime = false;
        _isUnlocked = true;
        _errorText = '';
      });
    }
    _newPasswordController.clear();
    _confirmPasswordController.clear();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text('🔒 备忘录',
            style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 20)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (_isUnlocked)
            IconButton(
              icon: Icon(Icons.lock_rounded, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
              onPressed: () => setState(() => _isUnlocked = false),
              tooltip: '锁定',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isUnlocked
              ? const _MemoList()
              : _isFirstTime
                  ? _ResetPasswordWidget(
                      controller1: _newPasswordController,
                      controller2: _confirmPasswordController,
                      errorText: _errorText,
                      onSubmit: _resetPassword,
                    )
                  : _PasswordInputWidget(
                      controller: _passwordController,
                      errorText: _errorText,
                      onSubmit: _verifyAndUnlock,
                    ),
    );
  }
}

/// 密码输入
class _PasswordInputWidget extends StatelessWidget {
  final TextEditingController controller;
  final String errorText;
  final VoidCallback onSubmit;

  const _PasswordInputWidget({
    required this.controller,
    required this.errorText,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.lock_outline_rounded,
                size: 64, color: theme.colorScheme.primary.withValues(alpha: 0.3)),
            const SizedBox(height: 24),
            Text('输入密码查看备忘录',
                style: TextStyle(
                  fontSize: 16,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                )),
            const SizedBox(height: 32),
            TextField(
              controller: controller,
              obscureText: true,
              onSubmitted: (_) => onSubmit(),
              decoration: InputDecoration(
                hintText: '请输入密码',
                errorText: errorText.isEmpty ? null : errorText,
                prefixIcon: Icon(Icons.password_rounded,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onSubmit,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('解锁'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 首次重置密码
class _ResetPasswordWidget extends StatelessWidget {
  final TextEditingController controller1;
  final TextEditingController controller2;
  final String errorText;
  final VoidCallback onSubmit;

  const _ResetPasswordWidget({
    required this.controller1,
    required this.controller2,
    required this.errorText,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.lock_reset_rounded,
                size: 64, color: theme.colorScheme.primary.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text('首次使用，请设置备忘录密码',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                )),
            const SizedBox(height: 8),
            Text('密码至少6位，请牢记！',
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                )),
            const SizedBox(height: 32),
            TextField(
              controller: controller1,
              obscureText: true,
              decoration: InputDecoration(
                hintText: '设置密码',
                prefixIcon: Icon(Icons.password_rounded,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller2,
              obscureText: true,
              onSubmitted: (_) => onSubmit(),
              decoration: InputDecoration(
                hintText: '确认密码',
                prefixIcon: Icon(Icons.password_rounded,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
            if (errorText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(errorText,
                    style: TextStyle(color: theme.colorScheme.error, fontSize: 13)),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onSubmit,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('确认设置'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 备忘录列表 — 改为 StatelessWidget，通过 context.watch 消费 Provider 数据
/// 这样保存备忘录时不会触发独立的 setState，避免 InheritedElement._dependents 冲突
class _MemoList extends StatelessWidget {
  const _MemoList();

  Future<void> _addMemo(BuildContext context) async {
    final content = await _showMemoDialog(context);
    if (content == null || content.trim().isEmpty) return;
    if (!context.mounted) return;
    await context.read<AppDataProvider>().addMemo(content.trim());
  }

  Future<void> _editMemo(BuildContext context, Memo memo) async {
    final result = await _showMemoDialog(context, initialContent: memo.content, memoId: memo.id);
    if (result == null || !context.mounted) return;
    if (result == 'deleted') {
      await context.read<AppDataProvider>().deleteMemo(memo.id);
      return;
    }
    if (result.trim().isEmpty) return;
    await context.read<AppDataProvider>().updateMemo(memo.id, result.trim());
  }

  Future<String?> _showMemoDialog(BuildContext context, {String? initialContent, int? memoId}) async {
    final controller = TextEditingController(text: initialContent ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(initialContent != null ? '编辑备忘' : '新建备忘',
              style: TextStyle(fontWeight: FontWeight.w600)),
          content: TextField(
            controller: controller,
            maxLines: 8,
            autofocus: true,
            decoration: InputDecoration(
              hintText: '输入备忘内容...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
          actions: [
            if (initialContent != null && memoId != null)
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'deleted'),
                child: Text('删除', style: TextStyle(color: theme.colorScheme.error)),
              ),
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
    return result;
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final memos = context.watch<AppDataProvider>().memos;

    return Stack(
      children: [
        if (memos.isEmpty)
          Center(
            child: Column(
              children: [
                Icon(Icons.note_alt_outlined,
                    size: 64, color: theme.colorScheme.onSurface.withValues(alpha: 0.15)),
                const SizedBox(height: 12),
                Text('暂无备忘录',
                    style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.3))),
              ],
            ),
          )
        else
          ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 100),
            itemCount: memos.length,
            itemBuilder: (context, index) {
              final memo = memos[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                ),
                child: InkWell(
                  onTap: () => _editMemo(context, memo),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          memo.content,
                          style: TextStyle(fontSize: 15, color: theme.colorScheme.onSurface),
                          maxLines: 5,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatDate(memo.updatedAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        // 添加按钮
        Positioned(
          left: 0, right: 0, bottom: 24,
          child: Center(
            child: FloatingActionButton.extended(
              onPressed: () => _addMemo(context),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              icon: const Icon(Icons.add),
              label: const Text('添加备忘'),
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }
}
