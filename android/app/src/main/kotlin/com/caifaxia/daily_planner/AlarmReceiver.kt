package com.caifaxia.daily_planner

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat

/// 闹钟触发时的广播接收器
/// 
/// 显示通知提醒用户
class AlarmReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "AlarmReceiver"
        private const val CHANNEL_ID = "todo_reminder"
        private const val CHANNEL_NAME = "待办提醒"
    }

    override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "闹钟触发!")

        val id = intent.getIntExtra(AlarmService.EXTRA_ID, 0)
        val title = intent.getStringExtra(AlarmService.EXTRA_TITLE) ?: "待办提醒"
        val message = intent.getStringExtra(AlarmService.EXTRA_MESSAGE) ?: ""

        showNotification(context, id, title, message)
    }

    private fun showNotification(context: Context, id: Int, title: String, message: String) {
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        // 创建通知渠道 (Android 8.0+)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "待办事项提醒通知"
                enableVibration(true)
            }
            notificationManager.createNotificationChannel(channel)
        }

        // 点击通知打开应用
        val pendingIntent = PendingIntent.getActivity(
            context,
            id,
            context.packageManager.getLaunchIntentForPackage(context.packageName),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setContentTitle(title)
            .setContentText(message)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .build()

        notificationManager.notify(id, notification)
        Log.d(TAG, "通知已显示: title=$title, message=$message")
    }
}