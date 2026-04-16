package com.caifaxia.daily_planner

import android.content.Context
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class WidgetService(private val context: Context, flutterEngine: FlutterEngine) {
    companion object {
        private const val CHANNEL = "com.caifaxia.daily_planner/widget"
        private const val TAG = "WidgetService"
    }

    init {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "updateWidget" -> {
                        val todos = call.argument<List<String>>("todos") ?: emptyList()
                        Log.d(TAG, "updateWidget: ${todos.size} todos")
                        TodoWidget.updateWidget(context, todos)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
        Log.d(TAG, "WidgetService initialized")
    }
}