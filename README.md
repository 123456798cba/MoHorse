# MoHorse清单 - 功能说明文档

## 📱 应用简介

**MoHorse清单** 是一款集待办清单、记账记账、备忘录于一体的效率工具，采用 Material Design 3 设计风格，支持 Android 平台。

## 🎯 核心功能

### 1. 待办清单
- **快速添加**：支持手动添加和 AI 智能识别
- **定时提醒**：支持设置闹钟提醒
- **日期管理**：按日期查看和管理待办
- **完成标记**：点击即可标记完成/未完成
- **批量操作**：左滑删除待办

### 2. 记账功能
- **收支记录**：支持收入和支出记录
- **分类管理**：多种预设分类（餐饮、交通、购物等）
- **日期筛选**：按日期查看账单明细
- **统计分析**：月度/年度收支统计图表

### 3. AI 智能录入
- **智能识别**：输入自然语言，自动识别待办和账单
- **示例**：输入"明天早上八点起床"自动创建待办
- **示例**：输入"今天购物花了三十"自动创建支出记录

### 4. 备忘录
- **密码保护**：支持设置密码保护隐私
- **富文本支持**：支持文字记录

### 5. 桌面小组件
- **实时同步**：显示今日待办清单
- **一键直达**：点击打开 App
- **精美设计**：渐变背景、圆角阴影

## 📂 项目结构

```
lib/
├── main.dart              # 应用入口
├── ai/                    # AI 解析模块
│   ├── ai_parser.dart     # 规则引擎解析
│   └── ai_llm_parser.dart # 大模型解析
├── database/              # 数据库层
│   └── database.dart      # Drift 数据库
├── providers/             # 状态管理
│   └── app_data_provider.dart
├── screens/               # 页面
│   ├── home_screen.dart   # 首页
│   ├── stats_screen.dart  # 统计页
│   ├── memo_screen.dart   # 备忘录
│   └── splash_screen.dart # 启动页
├── services/              # 服务
│   ├── notification_service.dart
│   ├── native_service.dart
│   └── password_service.dart
├── widgets/              # 组件
│   ├── ai_input_widget.dart
│   ├── calendar_widget.dart
│   ├── todo_list_widget.dart
│   └── bill_list_widget.dart
└── models/                # 数据模型
```

## 🛠 技术栈

- **框架**：Flutter 3.x
- **状态管理**：Provider
- **数据库**：Drift (SQLite)
- **本地通知**：flutter_local_notifications
- **原生桥接**：MethodChannel

## 📋 技术规格

- **compileSdk**: 35
- **minSdk**: 21
- **targetSdk**: 35
- **包名**: com.caifaxia.daily_planner

## 🎨 设计规范

- **主题色**: #6C63FF (紫色)
- **字体**: PingFang SC
- **设计风格**: Material Design 3
- **支持语言**: 中文、英文

## 📝 使用说明

### 首次使用
1. 安装 APK
2. 首次启动设置密码（如需要）
3. 开始添加待办和记账

### AI 录入
1. 点击底部 AI 录入按钮
2. 输入自然语言描述
3. 点击解析，确认添加

### 桌面小组件
1. 长按手机桌面
2. 添加小组件
3. 选择 "MoHorse TODO"
4. 小组件将自动同步今日待办

## 📄 许可证

仅供学习和内部测试使用