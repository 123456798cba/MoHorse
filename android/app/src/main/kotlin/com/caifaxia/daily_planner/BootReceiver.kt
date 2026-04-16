package com.caifaxia.daily_planner

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/// 开机自启动接收器
/// 
/// 手机重启后，需要重新设置闹钟（Android 系统会清除所有闹钟）
class BootReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "BootReceiver"
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            Log.d(TAG, "手机重启完成，发送通知到 Flutter")
            
            // 发送广播通知 Flutter 重新设置闹钟
            val flutterIntent = Intent("com.caifaxia.daily_planner.RESTORE_ALARMS")
            context.sendBroadcast(flutterIntent)
        }
    }
}
