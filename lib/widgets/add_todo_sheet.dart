import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_data_provider.dart';

/// 手动添加清单项弹窗
Future<void> showAddTodoSheet(BuildContext context) async {
  final provider = context.read<AppDataProvider>();
  final controller = TextEditingController();
  TimeOfDay? selectedTime;
  bool hasReminder = false;
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
              Text('添加清单',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(ctx).colorScheme.onSurface,
                  )),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: '输入待办事项...',
                  hintStyle: TextStyle(
                    color: Theme.of(ctx)
                        .colorScheme
                        .onSurface
                        .withAlpha(77),
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
              Row(
                children: [
                  // 选择日期
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
                      _formatDate(selectedDate),
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
                  const SizedBox(width: 12),
                  // 选择时间
                  OutlinedButton.icon(
                    onPressed: () async {
                      final time = await showTimePicker(
                        context: ctx,
                        initialTime: TimeOfDay.now(),
                      );
                      if (time != null) {
                        setModalState(() {
                          selectedTime = time;
                          hasReminder = true;
                        });
                      }
                    },
                    icon: Icon(
                      Icons.access_time_rounded,
                      size: 18,
                      color: Theme.of(ctx).colorScheme.primary,
                    ),
                    label: Text(
                      selectedTime != null
                          ? '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}'
                          : '设置时间',
                      style: TextStyle(
                        color: selectedTime != null
                            ? Theme.of(ctx).colorScheme.primary
                            : Theme.of(ctx)
                                .colorScheme
                                .onSurface
                                .withAlpha(153),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      side: BorderSide(
                        color: selectedTime != null
                            ? Theme.of(ctx).colorScheme.primary
                            : Theme.of(ctx)
                                .colorScheme
                                .outlineVariant
                                .withOpacity(0.5),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (selectedTime != null)
                    Row(
                      children: [
                        Icon(
                          Icons.notifications_active_rounded,
                          size: 16,
                          color: Theme.of(ctx).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '将提醒',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(ctx).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 20),
              // 确认按钮
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    final value = controller.text.trim();
                    if (value.isEmpty) return;
                    Navigator.of(ctx).pop();
                    String? timeStr;
                    if (selectedTime != null) {
                      timeStr = '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}';
                    }
                    await provider.addTodo(
                      content: value,
                      date: selectedDate,
                      time: timeStr,
                      hasReminder: hasReminder,
                    );
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('确认添加'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

String _formatDate(DateTime date) {
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