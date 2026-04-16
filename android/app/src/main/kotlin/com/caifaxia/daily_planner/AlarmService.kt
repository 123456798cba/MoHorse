package com.caifaxia.daily_planner

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/// 闹钟提醒服务
/// 
/// 通过 MethodChannel 暴露给 Flutter 调用：
/// - setAlarm(id, title, message, timestamp) - 设置闹钟
/// - cancelAlarm(id) - 取消闹钟
class AlarmService(private val context: Context, flutterEngine: FlutterEngine) {
    companion object {
        private const val CHANNEL = "com.caifaxia.daily_planner/alarm"
        private const val TAG = "AlarmService"
        const val ACTION_ALARM = "com.caifaxia.daily_planner.ALARM"
        const val EXTRA_ID = "alarm_id"
        const val EXTRA_TITLE = "alarm_title"
        const val EXTRA_MESSAGE = "alarm_message"
    }

    private val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

    init {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "setAlarm" -> {
                    val id = call.argument<Int>("id") ?: 0
                    val title = call.argument<String>("title") ?: "提醒"
                    val message = call.argument<String>("message") ?: ""
                    val timestamp = call.argument<Long>("timestamp") ?: 0L
                    
                    val success = setAlarm(id, title, message, timestamp)
                    if (success) result.success(true) else result.error("ERROR", "Failed to set alarm", null)
                }
                "cancelAlarm" -> {
                    val id = call.argument<Int>("id") ?: 0
                    cancelAlarm(id)
                    result.success(true)
                }
                "cancelAllAlarms" -> {
                    // 取消所有闹钟需要遍历，这里简化处理
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    /// 设置闹钟
    private fun setAlarm(id: Int, title: String, message: String, timestamp: Long): Boolean {
        return try {
            val intent = Intent(context, AlarmReceiver::class.java).apply {
                action = ACTION_ALARM
                putExtra(EXTRA_ID, id)
                putExtra(EXTRA_TITLE, title)
                putExtra(EXTRA_MESSAGE, message)
            }

            val pendingIntent = PendingIntent.getBroadcast(
                context,
                id,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            // 使用精确闹钟
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                if (alarmManager.canScheduleExactAlarms()) {
                    alarmManager.setExactAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        timestamp,
                        pendingIntent
                    )
                } else {
                    // 没有精确闹钟权限，使用非精确闹钟
                    alarmManager.setAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        timestamp,
                        pendingIntent
                    )
                }
            } else {
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    timestamp,
                    pendingIntent
                )
            }

            Log.d(TAG, "闹钟已设置: id=$id, title=$title, time=$timestamp")
            true
        } catch (e: Exception) {
            Log.e(TAG, "设置闹钟失败: ${e.message}")
            false
        }
    }

    /// 取消闹钟
    private fun cancelAlarm(id: Int) {
        val intent = Intent(context, AlarmReceiver::class.java).apply {
            action = ACTION_ALARM
        }
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        alarmManager.cancel(pendingIntent)
        Log.d(TAG, "闹钟已取消: id=$id")
    }
}