package com.caifaxia.daily_planner

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // 初始化闹钟服务
        AlarmService(this, flutterEngine)
        
        // 初始化小组件服务
        WidgetService(this, flutterEngine)
    }
}
