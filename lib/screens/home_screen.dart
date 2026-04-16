import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_data_provider.dart';
import '../widgets/calendar_widget.dart';
import '../widgets/todo_list_widget.dart';
import '../widgets/bill_list_widget.dart';
import '../widgets/ai_input_widget.dart';
import '../widgets/add_todo_sheet.dart';
import '../widgets/add_bill_sheet.dart';
import '../services/native_service.dart';
import 'todo_bill_tabs.dart';
import 'memo_screen.dart';

/// 主页面 - 日历 + 当日数据
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 1; // 默认首页

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          TodoTabPage(),
          _HomePage(),
          BillTabPage(),
          MemoScreen(),
        ],
      ),
      bottomNavigationBar: _BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
      floatingActionButton: _currentIndex == 1
          ? const AiInputButton()
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

/// 首页 - 日历 + 当日清单和账单
class _HomePage extends StatelessWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<AppDataProvider>();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text('MoHorse清单',
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            )),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.loadDayData(provider.selectedDate),
        child: CustomScrollView(
          slivers: [
            // 日历
            SliverToBoxAdapter(
              child: CalendarWidget(
                selectedDate: provider.selectedDate,
                onDateSelected: (date) => provider.selectDate(date),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 4)),

            // 当日概览
            SliverToBoxAdapter(
              child: _DaySummaryCard(
                date: provider.selectedDate,
                todoCount: provider.pendingTodoCount,
                expense: provider.todayExpense,
                income: provider.todayIncome,
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            // 快捷操作按钮
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _QuickActionButton(
                        icon: Icons.add_task_rounded,
                        label: '加清单',
                        color: theme.colorScheme.primary,
                        onTap: () => showAddTodoSheet(context),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _QuickActionButton(
                        icon: Icons.receipt_long_rounded,
                        label: '记一笔',
                        color: theme.colorScheme.error,
                        onTap: () => showAddBillSheet(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // 清单列表
            const SliverToBoxAdapter(child: TodoListWidget()),

            // 分割线
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Divider(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                  height: 24,
                ),
              ),
            ),

            // 账单列表
            const SliverToBoxAdapter(child: BillListWidget()),

            // 底部留白
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}

/// 当日概览卡片
class _DaySummaryCard extends StatelessWidget {
  final DateTime date;
  final int todoCount;
  final double expense;
  final double income;

  const _DaySummaryCard({
    required this.date,
    required this.todoCount,
    required this.expense,
    required this.income,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isToday = date.year == DateTime.now().year &&
        date.month == DateTime.now().month &&
        date.day == DateTime.now().day;
    final dateLabel = isToday ? '今天' : '${date.month}月${date.day}日';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          // 日期标签
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              dateLabel,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _SummaryItem(
                    icon: Icons.checklist_rtl_rounded,
                    label: '待办',
                    value: '$todoCount',
                    color: theme.colorScheme.primary,
                  ),
                  Container(width: 1, height: 24, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
                  _SummaryItem(
                    icon: Icons.arrow_downward_rounded,
                    label: '支出',
                    value: '¥${expense.abs().toStringAsFixed(0)}',
                    color: theme.colorScheme.error,
                  ),
                  Container(width: 1, height: 24, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
                  _SummaryItem(
                    icon: Icons.arrow_upward_rounded,
                    label: '收入',
                    value: '¥${income.toStringAsFixed(0)}',
                    color: Colors.green,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.6))),
            Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ],
    );
  }
}

/// 快捷操作按钮
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

/// 底部导航栏 - 三栏
class _BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const _BottomNavBar({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavTab(
                icon: Icons.checklist_rtl_rounded,
                label: '清单',
                isSelected: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavTab(
                icon: Icons.calendar_today_rounded,
                label: '首页',
                isSelected: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              _NavTab(
                icon: Icons.receipt_long_rounded,
                label: '账单',
                isSelected: currentIndex == 2,
                onTap: () => onTap(2),
              ),
              _NavTab(
                icon: Icons.lock_outline_rounded,
                label: '备忘录',
                isSelected: currentIndex == 3,
                onTap: () => onTap(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavTab({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isSelected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface.withValues(alpha: 0.35);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
