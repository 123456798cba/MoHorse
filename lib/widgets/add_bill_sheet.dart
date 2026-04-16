import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_data_provider.dart';

String _formatDateShort(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final dateOnly = DateTime(date.year, date.month, date.day);
  
  if (dateOnly == today) {
    return '今天';
  } else if (dateOnly == today.add(const Duration(days: 1))) {
    return '明天';
  } else if (dateOnly == today.subtract(const Duration(days: 1))) {
    return '昨天';
  } else {
    return '${date.month}/${date.day}';
  }
}

/// 手动添加账单弹窗
Future<void> showAddBillSheet(BuildContext context) async {
  final provider = context.read<AppDataProvider>();
  String? selectedCategory;
  final amountController = TextEditingController();
  final noteController = TextEditingController();
  bool isExpense = true;
  DateTime selectedDate = DateTime.now();

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setModalState) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: Theme.of(ctx).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(ctx)
                        .colorScheme
                        .onSurface
                        .withAlpha(51),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('记一笔',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(ctx).colorScheme.onSurface,
                  )),
              const SizedBox(height: 12),

              // 收入/支出切换
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('支出'),
                    selected: isExpense,
                    onSelected: (_) => setModalState(() => isExpense = true),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('收入'),
                    selected: !isExpense,
                    onSelected: (_) => setModalState(() => isExpense = false),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 金额输入
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: '输入金额',
                  prefixText: isExpense ? '-¥ ' : '+¥ ',
                  prefixStyle: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isExpense
                        ? Theme.of(ctx).colorScheme.error
                        : Colors.green,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(ctx)
                          .colorScheme
                          .outlineVariant
                          .withOpacity(0.5),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(ctx)
                          .colorScheme
                          .outlineVariant
                          .withOpacity(0.5),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(ctx).colorScheme.primary,
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
              const SizedBox(height: 12),

              // 日期选择
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: ctx,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) {
                        setModalState(() {
                          selectedDate = date;
                        });
                      }
                    },
                    icon: Icon(
                      Icons.calendar_today_rounded,
                      size: 18,
                      color: Theme.of(ctx).colorScheme.primary,
                    ),
                    label: Text(
                      _formatDateShort(selectedDate),
                      style: TextStyle(
                        color: Theme.of(ctx).colorScheme.primary,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      side: BorderSide(
                        color: Theme.of(ctx).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 分类选择
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: provider.categories
                    .where((c) => isExpense ? c.isDefault || true : c.name == '工资' || c.name == '其他')
                    .map((cat) {
                  final isSelected = selectedCategory == cat.name;
                  return GestureDetector(
                    onTap: () => setModalState(() => selectedCategory = cat.name),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(ctx).colorScheme.primaryContainer
                            : Theme.of(ctx)
                                .colorScheme
                                .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(ctx).colorScheme.primary
                              : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        '${cat.icon} ${cat.name}',
                        style: TextStyle(
                          fontSize: 13,
                          color: isSelected
                              ? Theme.of(ctx).colorScheme.onPrimaryContainer
                              : Theme.of(ctx)
                                  .colorScheme
                                  .onSurface
                                  .withAlpha(153),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              // 备注输入
              TextField(
                controller: noteController,
                decoration: InputDecoration(
                  hintText: '备注（可选）',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(ctx)
                          .colorScheme
                          .outlineVariant
                          .withOpacity(0.5),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(ctx)
                          .colorScheme
                          .outlineVariant
                          .withOpacity(0.5),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(ctx).colorScheme.primary,
                    ),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
              const SizedBox(height: 16),

              // 确认按钮
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    final amount = double.tryParse(amountController.text);
                    if (amount == null || amount <= 0) return;
                    Navigator.of(ctx).pop();
                    provider.addBill(
                      amount: isExpense ? -amount : amount,
                      category: selectedCategory ?? '其他',
                      note: noteController.text.trim(),
                      date: selectedDate,
                    );
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('确认'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
