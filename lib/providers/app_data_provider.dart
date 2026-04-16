import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import '../database/database.dart';
import '../ai/ai_parser.dart';
import '../services/notification_service.dart';
import '../services/native_service.dart';

/// 应用数据提供者 - 状态管理核心
class AppDataProvider extends ChangeNotifier {
  final AppDatabase _db;
  final AiParser _aiParser = AiParser();
  final NotificationService _notificationService = NotificationService();

  DateTime _selectedDate = DateTime.now();
  List<TodoItem> _todos = [];
  List<BillRecord> _bills = [];
  List<BillCategory> _categories = [];
  List<Memo> _memos = [];
  bool _isLoading = false;

  DateTime get selectedDate => _selectedDate;
  List<TodoItem> get todos => _todos;
  List<BillRecord> get bills => _bills;
  List<BillCategory> get categories => _categories;
  List<Memo> get memos => _memos;
  bool get isLoading => _isLoading;

  /// 当日总支出
  double get todayExpense {
    return _bills
        .where((b) => b.amount < 0)
        .fold(0.0, (sum, b) => sum + b.amount);
  }

  /// 当日总收入
  double get todayIncome {
    return _bills
        .where((b) => b.amount > 0)
        .fold(0.0, (sum, b) => sum + b.amount);
  }

  /// 未完成清单数
  int get pendingTodoCount => _todos.where((t) => !t.isCompleted).length;

  AppDataProvider(this._db) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initSilent();
    });
  }

  /// 静默初始化：一次性加载所有数据，只触发一次 notifyListeners
  Future<void> _initSilent() async {
    try {
      await _notificationService.init();
      await _notificationService.requestPermission();

      _categories = await (_db.select(_db.billCategories)
            ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
          .get();

      final dayStart = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      _todos = await (_db.select(_db.todoItems)
            ..where((t) => t.date.isBiggerOrEqualValue(dayStart) & t.date.isSmallerThanValue(dayEnd))
            ..orderBy([(t) => OrderingTerm.asc(t.time)]))
          .get();

      _bills = await (_db.select(_db.billRecords)
            ..where((b) => b.date.isBiggerOrEqualValue(dayStart) & b.date.isSmallerThanValue(dayEnd))
            ..orderBy([(b) => OrderingTerm.desc(b.createdAt)]))
          .get();

      _memos = await (_db.select(_db.memos)
            ..orderBy([(m) => OrderingTerm.desc(m.updatedAt)]))
          .get();

      _isLoading = false;
      notifyListeners();
      
      // 初始化完成后更新小组件
      await _updateWidget();
    } catch (e) {
      debugPrint('初始化失败: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 切换选中日期
  Future<void> selectDate(DateTime date) async {
    _selectedDate = DateTime(date.year, date.month, date.day);
    await loadDayData(_selectedDate);
  }

  /// 加载某天的数据
  Future<void> loadDayData(DateTime date) async {
    _isLoading = true;
    notifyListeners();

    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    _todos = await (_db.select(_db.todoItems)
          ..where((t) => t.date.isBiggerOrEqualValue(dayStart) & t.date.isSmallerThanValue(dayEnd))
          ..orderBy([
            (t) => OrderingTerm.asc(t.time),
          ]))
        .get();

    _bills = await (_db.select(_db.billRecords)
          ..where((b) => b.date.isBiggerOrEqualValue(dayStart) & b.date.isSmallerThanValue(dayEnd))
          ..orderBy([
            (b) => OrderingTerm.desc(b.createdAt),
          ]))
        .get();

    _isLoading = false;
    notifyListeners();
  }

  /// 加载分类列表
  Future<void> loadCategories() async {
    _categories = await (_db.select(_db.billCategories)
          ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
        .get();
    notifyListeners();
  }

  // ==================== 清单操作 ====================

  Future<void> addTodo({
    required String content,
    String? time,
    DateTime? date,
    bool hasReminder = false,
  }) async {
    final targetDate = date ?? _selectedDate;
    final companion = TodoItemsCompanion.insert(
      content: content,
      date: targetDate,
      time: Value(time),
      hasReminder: Value(hasReminder),
    );
    final id = await _db.into(_db.todoItems).insert(companion);

    if (hasReminder && time != null) {
      final parts = time.split(':');
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;
      final scheduledTime = DateTime(
        targetDate.year, targetDate.month, targetDate.day, hour, minute,
      );
      final now = DateTime.now();
      if (scheduledTime.isAfter(now)) {
        // 使用原生闹钟
        await NativeService.setAlarm(
          id: id,
          title: '📋 清单提醒',
          message: content,
          timestamp: scheduledTime.millisecondsSinceEpoch,
        );
        // 同时使用 Flutter 本地通知作为备用
        await _notificationService.scheduleReminder(
          id: id,
          title: '📋 清单提醒',
          body: content,
          scheduledTime: scheduledTime,
        );
      }
    }

    await loadDayData(_selectedDate);
    
    // 更新桌面小组件
    await _updateWidget();
  }

  Future<void> toggleTodo(int id, bool completed) async {
    await (_db.update(_db.todoItems)..where((t) => t.id.equals(id)))
        .write(TodoItemsCompanion(isCompleted: Value(completed)));
    await loadDayData(_selectedDate);
    await _updateWidget();
  }

  Future<void> deleteTodo(int id) async {
    await (_db.delete(_db.todoItems)..where((t) => t.id.equals(id))).go();
    await _notificationService.cancelReminder(id);
    await NativeService.cancelAlarm(id);
    await loadDayData(_selectedDate);
    await _updateWidget();
  }

  /// 更新桌面小组件
  Future<void> _updateWidget() async {
    // 获取今日未完成的待办
    final today = DateTime.now();
    final dayStart = DateTime(today.year, today.month, today.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    
    final todayTodos = await (_db.select(_db.todoItems)
          ..where((t) => t.date.isBiggerOrEqualValue(dayStart) & 
                        t.date.isSmallerThanValue(dayEnd) & 
                        t.isCompleted.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.time)])
          ..limit(5))
        .get();
    
    final todoList = todayTodos.map((t) => t.content).toList();
    await NativeService.updateWidget(todoList);
  }

  // ==================== 账单操作 ====================

  Future<void> addBill({
    required double amount,
    required String category,
    String note = '',
    DateTime? date,
  }) async {
    await _db.into(_db.billRecords).insert(BillRecordsCompanion.insert(
      amount: amount,
      category: category,
      note: Value(note),
      date: date ?? _selectedDate,
    ));
    await loadDayData(_selectedDate);
  }

  Future<void> deleteBill(int id) async {
    await (_db.delete(_db.billRecords)..where((b) => b.id.equals(id))).go();
    await loadDayData(_selectedDate);
  }

  // ==================== AI 解析录入 ====================

  Future<List<String>> parseAndSaveAll(String text) async {
    final results = _aiParser.parseMultiple(text);
    final messages = <String>[];

    for (final result in results) {
      switch (result.type) {
        case ParsedIntent.expense:
          if (result.expenseAmount != null) {
            await addBill(
              amount: result.expenseAmount!,
              category: result.expenseCategory ?? '其他',
              note: result.expenseNote ?? '',
              date: result.todoDate,
            );
            final abs = result.expenseAmount!.abs();
            final sign = result.expenseAmount! >= 0 ? '+' : '-';
            final dateInfo = result.dateLabel != null ? ' (${result.dateLabel})' : '';
            messages.add('💰 ${result.expenseCategory} $sign$abs$dateInfo');
          }
        case ParsedIntent.todo:
          String? timeStr;
          if (result.todoTime != null) {
            timeStr = '${result.todoTime!.hour.toString().padLeft(2, '0')}:${result.todoTime!.minute.toString().padLeft(2, '0')}';
          }
          await addTodo(
            content: result.todoContent ?? text,
            time: timeStr,
            date: result.todoDate,
            hasReminder: result.todoTime != null,
          );
          final dateInfo = result.dateLabel != null ? ' (${result.dateLabel})' : '';
          final timeInfo = timeStr != null ? ' $timeStr' : '';
          messages.add('📋 ${result.todoContent}$timeInfo$dateInfo');
        case ParsedIntent.unknown:
          break;
      }
    }

    if (messages.isEmpty) {
      messages.add('❓ 没太听懂，能再说清楚点吗？');
    }

    return messages;
  }

  Future<String> parseAndSave(String text) async {
    final results = await parseAndSaveAll(text);
    return results.join('\n');
  }

  // ==================== 统计数据 ====================

  Future<List<BillRecord>> getMonthBills(int year, int month) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);
    return (_db.select(_db.billRecords)
          ..where((b) => b.date.isBiggerOrEqualValue(start) & b.date.isSmallerThanValue(end)))
        .get();
  }

  Future<Map<String, double>> getMonthCategorySummary(int year, int month) async {
    final bills = await getMonthBills(year, month);
    final Map<String, double> summary = {};
    for (final bill in bills) {
      if (bill.amount < 0) {
        summary[bill.category] = (summary[bill.category] ?? 0) + bill.amount;
      }
    }
    return summary;
  }

  Future<Map<int, double>> getMonthDailyExpense(int year, int month) async {
    final bills = await getMonthBills(year, month);
    final Map<int, double> daily = {};
    for (final bill in bills) {
      if (bill.amount < 0) {
        daily[bill.date.day] = (daily[bill.date.day] ?? 0) + bill.amount;
      }
    }
    return daily;
  }

  // ==================== 年度统计 ====================

  /// 获取年度账单
  Future<List<BillRecord>> getYearBills(int year) async {
    final start = DateTime(year, 1, 1);
    final end = DateTime(year + 1, 1, 1);
    return (_db.select(_db.billRecords)
          ..where((b) => b.date.isBiggerOrEqualValue(start) & b.date.isSmallerThanValue(end)))
        .get();
  }

  /// 年度分类统计（支出）
  Future<Map<String, double>> getYearCategorySummary(int year) async {
    final bills = await getYearBills(year);
    final Map<String, double> summary = {};
    for (final bill in bills) {
      if (bill.amount < 0) {
        summary[bill.category] = (summary[bill.category] ?? 0) + bill.amount;
      }
    }
    return summary;
  }

  /// 月度支出统计（1-12月）
  Future<Map<int, double>> getYearMonthlyExpense(int year) async {
    final bills = await getYearBills(year);
    final Map<int, double> monthly = {};
    for (final bill in bills) {
      if (bill.amount < 0) {
        monthly[bill.date.month] = (monthly[bill.date.month] ?? 0) + bill.amount;
      }
    }
    return monthly;
  }

  /// 年度收入统计
  Future<double> getYearIncome(int year) async {
    final bills = await getYearBills(year);
    double total = 0;
    for (final b in bills) {
      if (b.amount > 0) total += b.amount;
    }
    return total;
  }

  /// 年度支出统计
  Future<double> getYearExpense(int year) async {
    final bills = await getYearBills(year);
    double total = 0;
    for (final b in bills) {
      if (b.amount < 0) total += b.amount;
    }
    return total;
  }

  /// 支出排行榜 Top 5
  Future<List<MapEntry<String, double>>> getYearTopCategories(int year) async {
    final summary = await getYearCategorySummary(year);
    final sorted = summary.entries.toList()
      ..sort((a, b) => a.value.abs().compareTo(b.value.abs()));
    return sorted.reversed.take(5).toList();
  }

  // ==================== 备忘录操作（数据由 Provider 统一管理）====================

  /// 加载所有备忘录
  Future<void> loadMemos() async {
    _memos = await (_db.select(_db.memos)
          ..orderBy([(m) => OrderingTerm.desc(m.updatedAt)]))
        .get();
    notifyListeners();
  }

  /// 获取所有备忘录（纯查询，不触发通知）
  Future<List<Memo>> getAllMemos() async {
    return (_db.select(_db.memos)
          ..orderBy([(m) => OrderingTerm.desc(m.updatedAt)]))
        .get();
  }

  Future<int> addMemo(String content) async {
    final companion = MemosCompanion.insert(content: content);
    final id = await _db.into(_db.memos).insert(companion);
    await loadMemos();
    return id;
  }

  Future<void> updateMemo(int id, String content) async {
    await (_db.update(_db.memos)..where((m) => m.id.equals(id)))
        .write(MemosCompanion(
      content: Value(content),
      updatedAt: Value(DateTime.now()),
    ));
    await loadMemos();
  }

  Future<void> deleteMemo(int id) async {
    await (_db.delete(_db.memos)..where((m) => m.id.equals(id))).go();
    await loadMemos();
  }
}
