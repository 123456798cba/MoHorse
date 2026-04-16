import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_data_provider.dart';
import '../widgets/todo_list_widget.dart';
import '../widgets/bill_list_widget.dart';
import '../widgets/add_todo_sheet.dart';
import '../widgets/add_bill_sheet.dart';
import 'stats_screen.dart';

/// 计划清单页面（独立 Tab）
class TodoTabPage extends StatelessWidget {
  const TodoTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<AppDataProvider>();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text('📋 今日清单',
            style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 20)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_outline_rounded, color: theme.colorScheme.primary),
            onPressed: () => showAddTodoSheet(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.loadDayData(DateTime.now()),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          children: [
            const TodoListWidget(),
          ],
        ),
      ),
    );
  }
}

/// 账单页面（独立 Tab）
class BillTabPage extends StatelessWidget {
  const BillTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<AppDataProvider>();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text('💰 今日账单',
            style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 20)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          // 统计按钮
          IconButton(
            icon: Icon(Icons.bar_chart_rounded, color: theme.colorScheme.primary),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StatsScreen()),
            ),
          ),
          // 添加按钮
          IconButton(
            icon: Icon(Icons.add_circle_outline_rounded, color: theme.colorScheme.error),
            onPressed: () => showAddBillSheet(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.loadDayData(DateTime.now()),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          children: [
            const BillListWidget(),
          ],
        ),
      ),
    );
  }
}
