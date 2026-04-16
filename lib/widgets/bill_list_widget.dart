import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/database.dart';
import '../providers/app_data_provider.dart';

/// 账单列表组件
class BillListWidget extends StatelessWidget {
  const BillListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppDataProvider>();
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            children: [
              Icon(Icons.receipt_long_rounded,
                  size: 20, color: theme.colorScheme.error),
              const SizedBox(width: 8),
              Text(
                '今日账单',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              Text(
                '¥${provider.todayExpense.abs().toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ),
        ),
        if (provider.bills.isEmpty)
          _buildEmptyState(theme, '暂无账单', '点击下方 + 记一笔或使用 AI 录入'),
        ...provider.bills.map((bill) => _BillItem(
              bill: bill,
              categories: provider.categories,
              onDelete: () => provider.deleteBill(bill.id),
            )),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.receipt_long_rounded,
                size: 48, color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
            const SizedBox(height: 12),
            Text(title,
                style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4))),
            Text(subtitle,
                style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3))),
          ],
        ),
      ),
    );
  }
}

class _BillItem extends StatelessWidget {
  final BillRecord bill;
  final List<BillCategory> categories;
  final VoidCallback onDelete;

  const _BillItem({
    required this.bill,
    required this.categories,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isExpense = bill.amount < 0;
    final color = isExpense ? theme.colorScheme.error : Colors.green;
    final category = categories.firstWhere(
      (c) => c.name == bill.category,
      orElse: () => BillCategory(id: 0, name: bill.category, icon: '📦', sortOrder: 0, isDefault: true),
    );

    return Dismissible(
      key: ValueKey(bill.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
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
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Text(
              category.icon,
              style: const TextStyle(fontSize: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bill.note.isNotEmpty ? bill.note : bill.category,
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    bill.category,
                    style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                  ),
                ],
              ),
            ),
            Text(
              '${isExpense ? '' : '+'}${bill.amount.abs().toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
