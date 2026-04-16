import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// 大模型 AI 解析服务（硅基流动 SiliconFlow）
///
/// 使用免费模型，国内访问快。
/// 开发者注册 https://siliconflow.cn 获取 API Key 后填入下方，
/// 用户无需任何配置即可使用。
class AiLlmParser {
  // ===================== 在这里填入你的 API Key =====================
  // 注册地址: https://siliconflow.cn
  // 新用户注册即送免费额度，日常使用完全够用
  static const String _apiKey = 'sk-mfpgybmqadmhowxxjeqtwpdmgyzfkkhizbpywzviujbwtvlz';
  // ================================================================

  static const String _baseUrl = 'https://api.siliconflow.cn/v1/chat/completions';
  // 免费模型：Qwen2.5-7B-Instruct
  static const String _model = 'Qwen/Qwen2.5-7B-Instruct';

  static bool _isCalling = false;

  /// 是否正在调用
  static bool get isCalling => _isCalling;

  /// 解析文本，返回 JSON 字符串
  ///
  /// 输入: "昨天买菜花了40，今天下午3点开会"
  /// 返回 JSON:
  /// {
  ///   "items": [
  ///     {"type":"expense","amount":-40,"category":"餐饮","note":"买菜","date":"2026-03-31"},
  ///     {"type":"todo","content":"开会","time":"15:00","date":"2026-04-01"}
  ///   ]
  /// }
  static Future<String> parse(String text) async {
    if (_apiKey == 'sk-xxx' || _apiKey.isEmpty) {
      debugPrint('🤖 API Key 未配置，跳过 LLM 解析');
      return '';
    }

    if (_isCalling) return '';
    _isCalling = true;

    try {
      final now = DateTime.now();
      final today = _fmtDate(now);
      final yesterday = _fmtDate(now.subtract(const Duration(days: 1)));
      final tomorrow = _fmtDate(now.add(const Duration(days: 1)));
      final dayAfterTomorrow = _fmtDate(now.add(const Duration(days: 2)));

      final systemPrompt = '''你是一个智能语音录入解析助手。用户通过语音输入自然语言，你需要将其精准解析为结构化JSON。

当前日期: $today (昨天=$yesterday, 明天=$tomorrow, 后天=$dayAfterTomorrow)

解析规则:
1. 支持混合输入: 一句话可同时包含记账和待办
2. **支出金额为负数, 收入金额为正数**
3. **收入关键词: 工资、薪资、薪水、收入、发工资、发钱、赚钱、盈利、奖金、红包、入账、到账、进账、收款、兼职等**
4. 自动分类: 餐饮|交通|购物|娱乐|住房|医疗|教育|通讯|社交|其他
5. 日期转 YYYY-MM-DD: 今天/昨天/明天/后天等相对日期要换算
6. 时间为 HH:MM 24小时制
7. **小数支持**: "三十六块七毛五"=36.75, "三十二元五角"=32.5, "七块五"=7.5, "七毛五"=0.75
8. **金额必须是浮点数**: 如 36.75 不能写成 37 或 37.0，7.5 不能写成 7

**重要**: "今天发工资发了一万"、"今天收入一万"、"今天赚钱了五千" 等都是收入(amount为正数)

严格只返回JSON, 不要任何其他文字。示例格式:
{"items":[{"type":"expense","amount":-40,"category":"餐饮","note":"买菜","date":"$yesterday"},{"type":"expense","amount":10000,"category":"工资","note":"发工资","date":"$today"},{"type":"todo","content":"开会","time":"15:00","date":"$today"}]}''';

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': text},
          ],
          'temperature': 0.1,
          'max_tokens': 500,
          'stream': false,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final content = body['choices'][0]['message']['content'] as String;
        // 清理 markdown 包裹
        String cleaned = content.trim();
        if (cleaned.startsWith('```')) {
          cleaned = cleaned.replaceAll(RegExp(r'^```\w*\n?'), '').replaceAll(RegExp(r'\n?```$'), '');
        }
        debugPrint('🤖 LLM 解析结果: $cleaned');
        return cleaned;
      } else {
        debugPrint('🤖 LLM 请求失败: ${response.statusCode}');
        return '';
      }
    } catch (e) {
      debugPrint('🤖 LLM 请求异常: $e');
      return '';
    } finally {
      _isCalling = false;
    }
  }

  static String _fmtDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}
