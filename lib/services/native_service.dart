import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 原生服务桥接
/// 
/// 提供闹钟提醒和桌面小组件功能
class NativeService {
  static const MethodChannel _alarmChannel = MethodChannel('com.caifaxia.daily_planner/alarm');
  static const MethodChannel _widgetChannel = MethodChannel('com.caifaxia.daily_planner/widget');

  /// 设置闹钟提醒
  /// 
  /// [id] 唯一标识（用于取消）
  /// [title] 通知标题
  /// [message] 通知内容
  /// [timestamp] 触发时间（毫秒时间戳）
  static Future<bool> setAlarm({
    required int id,
    required String title,
    required String message,
    required int timestamp,
  }) async {
    try {
      final result = await _alarmChannel.invokeMethod<bool>('setAlarm', {
        'id': id,
        'title': title,
        'message': message,
        'timestamp': timestamp,
      });
      debugPrint('⏰ 闹钟已设置: id=$id, title=$title, timestamp=$timestamp');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('⏰ 设置闹钟失败: ${e.message}');
      return false;
    }
  }

  /// 取消闹钟
  static Future<bool> cancelAlarm(int id) async {
    try {
      final result = await _alarmChannel.invokeMethod<bool>('cancelAlarm', {'id': id});
      debugPrint('⏰ 闹钟已取消: id=$id');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('⏰ 取消闹钟失败: ${e.message}');
      return false;
    }
  }

  /// 更新桌面小组件
  /// 
  /// [todos] 待办事项列表（最多显示5条）
  static Future<bool> updateWidget(List<String> todos) async {
    try {
      final result = await _widgetChannel.invokeMethod<bool>('updateWidget', {
        'todos': todos,
      });
      debugPrint('📱 小组件已更新: ${todos.length} 条');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('📱 更新小组件失败: ${e.message}');
      return false;
    }
  }

  /// 获取小组件 ID 列表
  static Future<List<int>> getWidgetIds() async {
    try {
      final result = await _widgetChannel.invokeMethod<List<dynamic>>('getWidgetIds');
      return result?.cast<int>() ?? [];
    } on PlatformException catch (e) {
      debugPrint('📱 获取小组件ID失败: ${e.message}');
      return [];
    }
  }
  
  /// 测试小组件（调试用）
  static Future<Map<String, dynamic>?> testWidget() async {
    try {
      final result = await _widgetChannel.invokeMethod<Map<dynamic, dynamic>>('testWidget');
      debugPrint('📱 测试小组件: $result');
      return result?.map((k, v) => MapEntry(k.toString(), v));
    } on PlatformException catch (e) {
      debugPrint('📱 测试小组件失败: ${e.message}');
      return null;
    }
  }
  
  /// 获取小组件调试信息
  static Future<Map<String, dynamic>?> getWidgetDebugInfo() async {
    try {
      final result = await _widgetChannel.invokeMethod<Map<dynamic, dynamic>>('debugInfo');
      debugPrint('📱 小组件调试信息: $result');
      return result?.map((k, v) => MapEntry(k.toString(), v));
    } on PlatformException catch (e) {
      debugPrint('📱 获取调试信息失败: ${e.message}');
      return null;
    }
  }
}