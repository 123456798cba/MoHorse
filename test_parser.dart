import 'package:flutter/material.dart';
import 'ai/ai_parser.dart';

void main() {
  final parser = AiParser();
  
  final testCases = [
    '今天发工资发了一万',
    '今天收入一万',
    '今天赚了五千',
    '工资到账了一万',
    '今天花了三十六块七毛五',
    '买菜花了三十六块七毛五',
    '今天购物花了三十七',
    '今天花了36.75',
    '今天花了七块五',
    '今天花了七毛五',
  ];
  
  for (final text in testCases) {
    final results = parser.parseMultiple(text);
    for (final r in results) {
      final type = r.type == ParsedIntent.expense ? '账单' : '清单';
      final amount = r.expenseAmount;
      print('输入: "$text" → 类型: $type, 金额: $amount');
    }
  }
}
