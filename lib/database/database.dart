import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

// ==================== 数据表定义 ====================

/// 清单项
class TodoItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get content => text().withLength(min: 1, max: 500)();
  DateTimeColumn get date => dateTime()();
  TextColumn get time => text().nullable()(); // HH:mm 格式
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  BoolColumn get hasReminder => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// 账单记录
class BillRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get amount => real()();
  TextColumn get category => text().withLength(min: 1, max: 50)();
  TextColumn get note => text().withLength(max: 500).withDefault(const Constant(''))();
  DateTimeColumn get date => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// 账单分类
class BillCategories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get icon => text().withDefault(const Constant('📝'))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isDefault => boolean().withDefault(const Constant(true))();
}

/// 备忘录
class Memos extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get content => text().withLength(min: 1)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// ==================== 数据库 ====================

@DriftDatabase(tables: [TodoItems, BillRecords, BillCategories, Memos])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        await _seedCategories();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.createTable(memos);
        }
      },
    );
  }

  Future<void> _seedCategories() async {
    final categories = [
      BillCategoriesCompanion.insert(name: '餐饮', icon: const Value('🍜'), sortOrder: const Value(0)),
      BillCategoriesCompanion.insert(name: '交通', icon: const Value('🚌'), sortOrder: const Value(1)),
      BillCategoriesCompanion.insert(name: '购物', icon: const Value('🛒'), sortOrder: const Value(2)),
      BillCategoriesCompanion.insert(name: '娱乐', icon: const Value('🎮'), sortOrder: const Value(3)),
      BillCategoriesCompanion.insert(name: '住房', icon: const Value('🏠'), sortOrder: const Value(4)),
      BillCategoriesCompanion.insert(name: '医疗', icon: const Value('💊'), sortOrder: const Value(5)),
      BillCategoriesCompanion.insert(name: '教育', icon: const Value('📚'), sortOrder: const Value(6)),
      BillCategoriesCompanion.insert(name: '工资', icon: const Value('💰'), sortOrder: const Value(7), isDefault: const Value(true)),
      BillCategoriesCompanion.insert(name: '其他', icon: const Value('📝'), sortOrder: const Value(8)),
    ];
    for (final c in categories) {
      await into(billCategories).insert(c);
    }
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'daily_planner.db'));
    return NativeDatabase.createInBackground(file);
  });
}
