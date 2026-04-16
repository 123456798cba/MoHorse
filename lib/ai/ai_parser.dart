/// AI 意图解析引擎（离线、规则驱动）
///
/// 支持单句和多句混合识别：
///   "买烟花了20，买菜花了30，今天要完成开发任务"
///   → Expense(买烟, -20), Expense(买菜, -30), Todo(完成开发任务)
library;

import 'package:flutter/material.dart';

/// 解析结果类型
enum ParsedIntent { todo, expense, unknown }

/// 解析结果
class ParsedResult {
  final ParsedIntent type;
  final String? todoContent;
  final TimeOfDay? todoTime;
  final DateTime? todoDate;
  final double? expenseAmount;
  final String? expenseCategory;
  final String? expenseNote;
  final String originalText;
  final String? dateLabel;

  ParsedResult({
    required this.type,
    this.todoContent,
    this.todoTime,
    this.todoDate,
    this.expenseAmount,
    this.expenseCategory,
    this.expenseNote,
    required this.originalText,
    this.dateLabel,
  });
}

class AiParser {
  static const Map<String, double> _cnNumberMap = {
    '零': 0,
    '〇': 0,
    '一': 1,
    '壹': 1,
    '二': 2,
    '贰': 2,
    '两': 2,
    '三': 3,
    '叁': 3,
    '四': 4,
    '肆': 4,
    '五': 5,
    '伍': 5,
    '六': 6,
    '陆': 6,
    '七': 7,
    '柒': 7,
    '八': 8,
    '捌': 8,
    '九': 9,
    '玖': 9,
    '十': 10,
    '拾': 10,
    '百': 100,
    '佰': 100,
    '千': 1000,
    '仟': 1000,
    '万': 10000,
    '萬': 10000,
  };

  static final List<MapEntry<String, String>> _categoryEntries = [
    const MapEntry('餐饮',
        '吃 饭 餐 外卖 早餐 午餐 晚餐 夜宵 买菜 菜 水果 零食 奶茶 咖啡 饮料 火锅 烧烤 面包 超市 烟 酒 水 餐厅 饭店 食堂 餐馆 小吃 快餐 正餐 早点 晚餐 聚餐 请客'),
    const MapEntry('交通',
        '打车 地铁 公交 出租 滴滴 高铁 火车 飞机 油费 停车 过路费 车票 机票 船票 打车费 交通费 加油 高速费 停车费 地铁票 公交卡'),
    const MapEntry('购物',
        '衣服 裤子 鞋 包 网购 淘宝 京东 拼多多 日用品 购物 买东西 商场 超市 便利店 服饰 化妆品 电子产品 数码产品 生活用品 家居用品'),
    const MapEntry(
        '娱乐', '电影 游戏 唱歌 KTV 旅游 门票 演出 娱乐 玩 休闲 度假 景点 游乐园 电影院 剧院 演唱会 音乐会 体育比赛'),
    const MapEntry(
        '住房', '房租 水电 电费 水费 燃气 物业 网费 房租费 水电费 燃气费 物业费 宽带费 有线电视 取暖费 维修费 装修费'),
    const MapEntry('医疗', '看病 医院 药 体检 医疗 医生 诊所 药店 药品 治疗 检查 手术 住院 疫苗 医保 医疗费用'),
    const MapEntry(
        '教育', '学费 书 课程 培训 教育 学习 学校 大学 中学 小学 幼儿园 辅导班 补习班 兴趣班 教材 课本 文具 学费 报名费'),
    const MapEntry('通讯', '话费 手机费 流量 宽带 电话 短信 通讯费 网费 宽带费 手机卡 手机号'),
    const MapEntry('社交', '聚会 请客 送礼 红包 人情 社交 朋友 同学 同事 婚礼 生日 节日 礼品 礼物'),
    const MapEntry('其他', '其他 杂项 杂费 其他支出 其他费用'),
  ];

  static const List<String> _incomeKeywords = [
    '工资',
    '薪资',
    '薪水',
    '收入',
    '报销',
    '奖金',
    '红包',
    '收款',
    '到账',
    '入账',
    '进账',
    '回款',
    '稿费',
    '兼职',
    '副业',
    '投资收益',
    '理财收益',
    '股息',
    '分红',
    '利息',
    '租金',
    '补贴',
    '津贴',
    '福利',
    '年终奖',
    '绩效奖',
    '发工资',
    '发钱',
    '赚钱',
    '盈利',
    '利润',
    '收获',
    '得到',
    '领到',
    '提成',
    '佣金',
    '一天',
    '一天的收入',
    '今日收入',
    '今日工资',
  ];

  /// "提醒"相关关键词 —— 含有这些的一律识别为清单，不是账单
  static const List<String> _todoPriorityKeywords = [
    '提醒',
    '记得',
    '别忘了',
    '别忘了要',
    '需要',
    '要',
    '计划',
    '安排',
    '准备',
    '记得要',
  ];

  // ==================== 主解析 ====================

  List<ParsedResult> parseMultiple(String text) {
    final cleaned = text.trim();
    if (cleaned.isEmpty)
      return [ParsedResult(type: ParsedIntent.unknown, originalText: text)];

    // 按标点分句
    final sentences = cleaned
        .split(RegExp(r'[，。！？,\.\!\?；;、\n]+'))
        .where((s) => s.trim().isNotEmpty)
        .toList();

    if (sentences.length > 1) {
      return sentences
          .map((s) => _parseSingle(s.trim()))
          .where((r) => r.type != ParsedIntent.unknown)
          .toList();
    }

    // 单句：尝试按"X个X"数量模式拆分
    final parts = _trySplitByCount(cleaned);
    if (parts.length > 1) {
      return parts
          .map((p) => _parseSingle(p.trim()))
          .where((r) => r.type != ParsedIntent.unknown)
          .toList();
    }

    return [_parseSingle(cleaned)];
  }

  ParsedResult parse(String text) => _parseSingle(text.trim());

  /// 拆分 "完成五篇作文，三篇日记" → ["完成五篇作文", "完成三篇日记"]
  List<String> _trySplitByCount(String text) {
    // 匹配 "完成/写/读 + 数字 + 量词 + 名词" 的重复模式
    final pattern = RegExp(
        r'(.+?(?:完成|写|读|做|弄|买|做|去|打|看)\s*(?:了\s*)?(?:\d+|[零一二三四五六七八九十百]+)\s*(?:篇|本|个|次|道|项|份|杯|碗|盒|瓶|件|张|页|首|段|课|套)\s*\S+?)');
    final matches = pattern.allMatches(text);
    if (matches.length >= 2) {
      return matches.map((m) => m.group(0)!).toList();
    }
    return [text];
  }

  ParsedResult _parseSingle(String text) {
    if (text.isEmpty)
      return ParsedResult(type: ParsedIntent.unknown, originalText: text);

    final hasAmount = _extractAmount(text) != null;
    final hasExpenseKeyword = _hasExpenseKeyword(text);
    final hasTodoPriority = _hasTodoPriority(text);
    final hasTodoPattern = _hasTodoPattern(text);
    final hasIncomeKeyword = _incomeKeywords.any((k) => text.contains(k));

    // 关键判断逻辑：
    // 1. 有"提醒/记得"等词 → 一定是清单
    // 2. 有收入关键词 + 有金额 → 收入账单
    // 3. 有消费关键词 + 有金额 → 支出账单
    // 4. 有金额（无消费关键词）+ 无清单词 → 账单
    // 5. 有清单模式 → 清单
    // 6. 兜底 → 清单

    if (hasTodoPriority) {
      return _parseTodo(text);
    }
    if (hasIncomeKeyword && hasAmount) {
      return _parseExpense(text);
    }
    if (hasExpenseKeyword && hasAmount) {
      return _parseExpense(text);
    }
    if (hasAmount && !hasTodoPattern && !hasTodoPriority) {
      return _parseExpense(text);
    }
    if (hasTodoPattern) {
      return _parseTodo(text);
    }
    // 兜底：当无法确定时，如果有金额就按账单，否则按清单
    if (hasAmount) {
      return _parseExpense(text);
    }
    return _parseTodo(text);
  }

  // ==================== 账单解析 ====================

  ParsedResult _parseExpense(String text) {
    final amount = _extractAmount(text);
    // 检查是否是收入：收入关键词 或 金额提取时有收入相关模式
    final isIncome = _incomeKeywords.any((k) => text.contains(k)) ||
        RegExp(r'(?:收入|入账|到账|进账|发了|赚了|收款|领了|获得|收到|提成|佣金|工资|奖金)\s*\d)').hasMatch(text);
    final actualAmount =
        isIncome ? (amount?.abs() ?? 0) : -(amount?.abs() ?? 0);

    String category = '其他';
    for (final entry in _categoryEntries) {
      final keywords = entry.value.split(' ');
      for (final keyword in keywords) {
        if (text.contains(keyword)) {
          category = entry.key;
          break;
        }
      }
      if (category != '其他') break;
    }

    final note = _extractExpenseNote(text, amount);
    final dateResult = _extractDate(text);

    return ParsedResult(
      type: ParsedIntent.expense,
      expenseAmount: actualAmount,
      expenseCategory: category,
      expenseNote: note,
      todoDate: dateResult.date,
      dateLabel: dateResult.label,
      originalText: text,
    );
  }

  // ==================== 清单解析 ====================

  ParsedResult _parseTodo(String text) {
    final dateResult = _extractDate(text);
    final targetTime = _extractTime(text);

    String content = text;
    if (dateResult.matchedText.isNotEmpty) {
      content = content.replaceAll(dateResult.matchedText, '');
    }
    content = content.replaceAll(RegExp(r'(今天|今日|明天|明日|后天|大后天|昨天|前天|大前天)'), '');
    content = content.replaceAll(
        RegExp(r'(?:零|〇|一|二|三|四|五|六|七|八|九|十|壹|贰|叁|肆|伍|陆|柒|捌|玖|拾)[月]'), '');
    content = content.replaceAll(RegExp(r'\d{1,2}月'), '');
    content = content.replaceAll(RegExp(r'\d{1,2}[日号]'), '');
    content = content.replaceAll(RegExp(r'(提醒我|提醒我去|提醒我)'), '');
    content = content.replaceAll(RegExp(r'(要|需要|记得|记得要|别忘了)'), '');
    content = content.replaceAll(RegExp(r'\d{1,2}[点时:：]\d{0,2}'), '');
    content = content.replaceAll(RegExp(r'(早上|上午|中午|下午|晚上|凌晨|夜里)'), '');
    content = content.replaceAll(RegExp(r'(完成|做完|弄完)$'), '');
    content = content.trim();

    if (content.isEmpty) content = text;

    return ParsedResult(
      type: ParsedIntent.todo,
      todoContent: content,
      todoTime: targetTime,
      todoDate: dateResult.date,
      dateLabel: dateResult.label,
      originalText: text,
    );
  }

  // ==================== 日期提取（增强版）====================

  ({DateTime? date, String? label, String matchedText}) _extractDate(
      String text) {
    final now = DateTime.now();

    // 1. 相对日期
    const relativePatterns = [
      ('大前天', -3),
      ('前天', -2),
      ('昨天', -1),
      ('今天', 0),
      ('今日', 0),
      ('明天', 1),
      ('明日', 1),
      ('后天', 2),
      ('大后天', 3),
    ];
    for (final (keyword, offset) in relativePatterns) {
      if (text.contains(keyword)) {
        return (
          date: DateTime(now.year, now.month, now.day + offset),
          label: keyword,
          matchedText: keyword,
        );
      }
    }

    // 2. 中文月份：四月十一日/号、十一月初三 等
    final cnMonthMatch = RegExp(
            r'(十[一二三四五六七八九]?|[一二三四五六七八九]|十一)月(\d{1,2}|十[一二三四五六七八九]?|[一二三四五六七八九]|二十[一二三四五六七八九]?)[日号]?')
        .firstMatch(text);
    if (cnMonthMatch != null) {
      final month = _cnSimpleNumber(cnMonthMatch.group(1)!);
      final day = _tryParseDay(cnMonthMatch.group(2)!);
      if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
        int year = now.year;
        if (month < now.month || (month == now.month && day < now.day)) year++;
        return (
          date: DateTime(year, month, day),
          label: '$month月$day日',
          matchedText: cnMonthMatch.group(0)!,
        );
      }
    }

    // 3. 数字月份：4月11日/号
    final mdMatch = RegExp(r'(\d{1,2})月(\d{1,2})[日号]?').firstMatch(text);
    if (mdMatch != null) {
      final month = int.parse(mdMatch.group(1)!);
      final day = int.parse(mdMatch.group(2)!);
      if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
        int year = now.year;
        if (month < now.month || (month == now.month && day < now.day)) year++;
        return (
          date: DateTime(year, month, day),
          label: '$month月$day日',
          matchedText: mdMatch.group(0)!,
        );
      }
    }

    // 4. X号（当月）
    final dayMatch = RegExp(r'(\d{1,2})号').firstMatch(text);
    if (dayMatch != null) {
      final day = int.parse(dayMatch.group(1)!);
      if (day >= 1 && day <= 31) {
        int month = now.month;
        int year = now.year;
        if (day < now.day) {
          month++;
          if (month > 12) {
            month = 1;
            year++;
          }
        }
        return (
          date: DateTime(year, month, day),
          label: '$month月$day日',
          matchedText: dayMatch.group(0)!,
        );
      }
    }

    // 5. 下周X / 这周X
    final weekMatch = RegExp(r'(下?周|这周)([一二三四五六日天])').firstMatch(text);
    if (weekMatch != null) {
      final isNext = weekMatch.group(1)!.contains('下');
      const weekDayMap = {
        '一': 1,
        '二': 2,
        '三': 3,
        '四': 4,
        '五': 5,
        '六': 6,
        '日': 7,
        '天': 7
      };
      final target = weekDayMap[weekMatch.group(2)!] ?? 1;
      int diff = target - now.weekday;
      if (isNext) diff += 7;
      if (diff <= 0) diff += 7;
      return (
        date: DateTime(now.year, now.month, now.day + diff),
        label: '${weekMatch.group(1)}${weekMatch.group(2)}',
        matchedText: weekMatch.group(0)!,
      );
    }

    return (date: null, label: null, matchedText: '');
  }

  int _tryParseDay(String s) {
    final n = int.tryParse(s);
    if (n != null) return n;
    return _cnSimpleNumber(s);
  }

  // ==================== 金额提取 ====================

  double? _extractAmount(String text) {
    // 1. "花了XX"、"买XX花了XX" 模式（支出）
    final r1 = RegExp(
        r'(?:花了|付了|用了|花了|花费|支出|消费|花费了|支付了|用掉了)\s*(\d+\.?\d*)');
    var match = r1.firstMatch(text);
    if (match != null) return double.tryParse(match.group(1)!);

    // 2. "XX块"、"XX元" 模式（支出/收入）
    final r2 = RegExp(r'(\d+\.?\d*)\s*(?:块钱|元钱|块人民币|元人民币|块|元)(?![点时:：\d])');
    match = r2.firstMatch(text);
    if (match != null) return double.tryParse(match.group(1)!);

    // 3. "收入XX"、"入账XX"、"到账XX"、"发了XX"、"赚了XX" 模式（收入）
    final r3 = RegExp(
        r'(?:收入|入账|到账|进账|发了|赚了|收款|领了|获得|收到|提成|佣金|工资|奖金)\s*(\d+\.?\d*)');
    match = r3.firstMatch(text);
    if (match != null) return double.tryParse(match.group(1)!);

    // 4. "数字+收入/工资/奖金" 模式 - 更宽松的匹配
    final r4 = RegExp(r'(\d+)\s*(?:元|块|万|千)');
    match = r4.firstMatch(text);
    if (match != null) {
      var amount = double.tryParse(match.group(1)!);
      if (amount != null) {
        if (text.contains('万') && amount < 100) {
          return amount * 10000;
        }
        if (text.contains('千') && amount < 100) {
          return amount * 1000;
        }
        return amount;
      }
    }

    // 5. 纯数字结尾（需要配合关键词）
    if (_hasExpenseKeyword(text) || _incomeKeywords.any((k) => text.contains(k))) {
      final r5 = RegExp(r'(\d+\.?\d*)\s*$');
      match = r5.firstMatch(text);
      if (match != null) return double.tryParse(match.group(1)!);
    }

    // 6. 中文数字（最重要：支持"一万"、"一万"等中文大写数字）
    final chineseAmount = _extractChineseNumber(text);
    if (chineseAmount != null) return chineseAmount;

    return null;
  }

  double? _extractChineseNumber(String text) {
    // 支持各种小数形式：
    // 三十六块七毛五 → 36.75
    // 三十二元五角 → 32.5
    // 七块五 → 7.5
    // 七毛五 → 0.75
    // 一万 → 10000
    
    // 提取所有中文字符和数字
    final cnNums = '零〇一二三四五六七八九十百千万壹贰叁肆伍陆柒捌玖拾佰仟萬两';
    
    int i = 0;
    double? bestMatch = null;
    int bestMatchLen = 0;
    
    while (i < text.length) {
      // 跳过非中文字符
      while (i < text.length && !cnNums.contains(text[i])) {
        i++;
      }
      if (i >= text.length) break;
      
      // 从这里开始尝试解析
      int j = i;
      double intVal = 0;
      double fraction = 0;
      bool hasUnit = false;
      
      // 读取整数部分
      while (j < text.length && cnNums.contains(text[j])) {
        j++;
      }
      final intStr = text.substring(i, j);
      if (intStr.isNotEmpty) {
        intVal = _parseChineseNumberCore(intStr);
      }
      
      // 跳过"个"、"块"、"元"
      if (j < text.length && '个块元'.contains(text[j])) {
        hasUnit = true;
        j++;
      }
      
      // 如果有"块/元"，尝试读取小数部分
      if (hasUnit) {
        // 读取小数部分的中文数字
        while (j < text.length && cnNums.contains(text[j])) {
          j++;
        }
        final fracStr = text.substring(i + intStr.length + 1, j);
        
        if (fracStr.isNotEmpty) {
          // 解析小数部分
          double fracVal = _parseChineseNumberCore(fracStr);
          
          // 判断是小数点后一位还是两位
          if (fracStr.length == 1) {
            // "七" -> 0.7
            fraction = fracVal / 10;
          } else if (fracStr.length == 2) {
            // "七五" -> 0.75
            fraction = fracVal / 100;
          } else {
            // 更长的情况
            fraction = fracVal / (fracStr.length == 3 ? 1000 : 10000);
          }
        }
      }
      
      // 计算总值
      final total = intVal + fraction;
      
      // 选择最长的匹配
      if (j - i > bestMatchLen && total > 0) {
        bestMatch = total;
        bestMatchLen = j - i;
      }
      
      i++;
    }
    
    return bestMatch;
  }
  
  double _parseChineseNumberCore(String chars) {
    double result = 0;
    double current = 0;

    for (int i = 0; i < chars.length; i++) {
      final char = chars[i];
      final value = _cnNumberMap[char];
      if (value == null) continue;

      if (value >= 10000) {
        result += current * value;
        current = 0;
      } else if (value >= 100) {
        current = (current == 0 ? 1 : current) * value;
      } else if (value >= 10) {
        current = (current == 0 ? 1 : current) * value;
      } else {
        current = value;
      }
    }
    result += current;

    return result;
  }

  // ==================== 时间提取 ====================

  TimeOfDay? _extractTime(String text) {
    final digitalMatch = RegExp(r'(\d{1,2})[点时:：](\d{1,2})?').firstMatch(text);
    if (digitalMatch != null) {
      int hour = int.parse(digitalMatch.group(1)!);
      int minute =
          digitalMatch.group(2) != null ? int.parse(digitalMatch.group(2)!) : 0;

      if (text.contains('下午') || text.contains('晚上') || text.contains('夜里')) {
        if (hour < 12) hour += 12;
      } else if (text.contains('凌晨')) {
        if (hour >= 12) hour -= 12;
      }

      return TimeOfDay(hour: hour.clamp(0, 23), minute: minute.clamp(0, 59));
    }

    return null;
  }

  // ==================== 辅助方法 ====================

  bool _hasExpenseKeyword(String text) {
    const keywords = [
      '花了',
      '用了',
      '付了',
      '消费',
      '支出',
      '买了',
      '开销',
      '扣了',
      '买单',
      '结账',
      '块钱',
      '元',
      '块'
    ];
    return keywords.any((k) => text.contains(k)) ||
        _incomeKeywords.any((k) => text.contains(k));
  }

  bool _hasTodoPriority(String text) {
    return _todoPriorityKeywords.any((k) => text.contains(k));
  }

  bool _hasTodoPattern(String text) {
    const keywords = ['去', '回', '打', '写', '看', '做', '开', '完成', '安排', '准备'];
    return keywords.any((k) => text.contains(k));
  }

  String _extractExpenseNote(String text, double? amount) {
    String note = text;
    if (amount != null) {
      note = note.replaceAll(RegExp(r'\d+\.?\d*'), '');
      note = note.replaceAll(RegExp(r'[零〇一二三四五六七八九十百千万两壹贰叁肆伍陆柒捌玖拾佰仟萬]+'), '');
    }
    note = note.replaceAll(
        RegExp(r'(花了|用了|付了|消费|支出|买了|开销|扣了|买单|结账|收入|报销|到账|块|元|钱)'), '');
    note = note.replaceAll(RegExp(r'(今天|明天|后天|昨天|前天|大前天|大后天|今日|明日|下周|这周)'), '');
    note = note.replaceAll(
        RegExp(r'(?:零|〇|一|二|三|四|五|六|七|八|九|十|壹|贰|叁|肆|伍|陆|柒|捌|玖|拾)[月]'), '');
    note = note.replaceAll(RegExp(r'\d{1,2}月'), '');
    note = note.replaceAll(RegExp(r'[日号]'), '');
    note = note.trim();
    return note.isEmpty ? '' : note;
  }

  int _cnSimpleNumber(String s) {
    if (s.length == 1) return _cnNumberMap[s]?.toInt() ?? 0;
    if (s == '十') return 10;
    if (s.length == 2 && s.startsWith('十')) {
      return 10 + (_cnNumberMap[s[1]]?.toInt() ?? 0);
    }
    if (s.length == 2 && s.endsWith('十')) {
      return (_cnNumberMap[s[0]]?.toInt() ?? 0) * 10;
    }
    if (s == '十一') return 11;
    if (s == '十二') return 12;
    return 0;
  }
}
