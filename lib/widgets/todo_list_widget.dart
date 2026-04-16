import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/database.dart';
import '../providers/app_data_provider.dart';

/// 清单列表组件
class TodoListWidget extends StatelessWidget {
  const TodoListWidget({super.key});

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
              Icon(Icons.checklist_rtl_rounded,
                  size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                '今日清单',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              Text(
                '${provider.todos.where((t) => !t.isCompleted).length} 未完成',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
        if (provider.todos.isEmpty)
          _buildEmptyState(theme, '暂无清单', '点击下方 + 添加或使用 AI 录入'),
        ...provider.todos.map((todo) => _TodoItem(
              todo: todo,
              onToggle: () => provider.toggleTodo(todo.id, !todo.isCompleted),
              onDelete: () => provider.deleteTodo(todo.id),
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
            Icon(Icons.checklist_rtl_rounded,
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

class _TodoItem extends StatelessWidget {
  final TodoItem todo;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _TodoItem({
    required this.todo,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dismissible(
      key: ValueKey(todo.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.delete_outline, color: theme.colorScheme.error),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: todo.isCompleted
                ? theme.colorScheme.outlineVariant.withOpacity(0.3)
                : theme.colorScheme.outlineVariant.withOpacity(0.5),
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          leading: GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: todo.isCompleted
                    ? theme.colorScheme.primary
                    : Colors.transparent,
                border: Border.all(
                  color: todo.isCompleted
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                  width: 2,
                ),
              ),
              child: todo.isCompleted
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ),
          title: Text(
            todo.content,
            style: TextStyle(
              fontSize: 15,
              decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
              color: todo.isCompleted
                  ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
                  : theme.colorScheme.onSurface,
            ),
          ),
          subtitle: todo.time != null
              ? Text(
                  '🕐 ${todo.time}${todo.hasReminder ? ' (已设提醒)' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.primary.withValues(alpha: 0.7),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
