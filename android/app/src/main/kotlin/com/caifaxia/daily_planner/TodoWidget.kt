package com.caifaxia.daily_planner

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import android.util.Log

class TodoWidget : AppWidgetProvider() {
    
    companion object {
        private const val TAG = "MoHorseWidget"
        const val ACTION_UPDATE = "com.caifaxia.daily_planner.UPDATE_WIDGET"
        const val EXTRA_TODOS = "todos"

        fun updateWidget(context: Context, todos: List<String>) {
            Log.d(TAG, "updateWidget: ${todos.size} todos")
            
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val componentName = ComponentName(context, TodoWidget::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)
            
            Log.d(TAG, "Widget IDs: ${appWidgetIds.contentToString()}")
            
            for (appWidgetId in appWidgetIds) {
                updateAppWidget(context, appWidgetManager, appWidgetId, todos)
            }
        }

        private fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int,
            todos: List<String>
        ) {
            Log.d(TAG, "Updating widget $appWidgetId")
            
            try {
                val views = RemoteViews(context.packageName, R.layout.simple_widget)

                // 设置日期
                val now = java.util.Calendar.getInstance()
                val month = now.get(java.util.Calendar.MONTH) + 1
                val day = now.get(java.util.Calendar.DAY_OF_MONTH)
                views.setTextViewText(R.id.widget_date, "${month}月${day}日")

                // 设置列表内容
                if (todos.isEmpty()) {
                    views.setTextViewText(R.id.widget_list, "暂无清单")
                } else {
                    val sb = StringBuilder()
                    for (todo in todos.take(5)) {
                        sb.append("○ $todo\n")
                    }
                    views.setTextViewText(R.id.widget_list, sb.toString().trim())
                    Log.d(TAG, "Set text: ${sb.toString().trim()}")
                }

                // 点击打开App
                val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
                if (intent != null) {
                    val pendingIntent = PendingIntent.getActivity(
                        context, 0, intent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    )
                    views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
                }

                appWidgetManager.updateAppWidget(appWidgetId, views)
                Log.d(TAG, "Widget $appWidgetId updated OK")
            } catch (e: Exception) {
                Log.e(TAG, "Error updating widget: ${e.message}", e)
            }
        }
    }

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        Log.d(TAG, "onUpdate: ${appWidgetIds.contentToString()}")
        
        for (appWidgetId in appWidgetIds) {
            try {
                val views = RemoteViews(context.packageName, R.layout.simple_widget)
                val now = java.util.Calendar.getInstance()
                val month = now.get(java.util.Calendar.MONTH) + 1
                val day = now.get(java.util.Calendar.DAY_OF_MONTH)
                views.setTextViewText(R.id.widget_date, "${month}月${day}日")
                views.setTextViewText(R.id.widget_list, "暂无清单")
                appWidgetManager.updateAppWidget(appWidgetId, views)
                Log.d(TAG, "Initial widget $appWidgetId set")
            } catch (e: Exception) {
                Log.e(TAG, "Error in onUpdate: ${e.message}", e)
            }
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "onReceive: ${intent.action}")
        super.onReceive(context, intent)
        
        if (intent.action == ACTION_UPDATE) {
            val todos = intent.getStringArrayListExtra(EXTRA_TODOS) ?: emptyList()
            Log.d(TAG, "Received update with ${todos.size} todos")
            updateWidget(context, todos)
        }
    }
    
    override fun onEnabled(context: Context) {
        Log.d(TAG, "Widget enabled (first added)")
    }
    
    override fun onDisabled(context: Context) {
        Log.d(TAG, "Widget disabled (last removed)")
    }
}