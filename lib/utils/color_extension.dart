import 'package:flutter/material.dart';

/// 颜色扩展方法，添加withValues方法以兼容现有代码
extension ColorExtension on Color {
  /// 为颜色添加透明度
  Color withValues({double alpha = 1.0}) {
    return withAlpha((alpha * 255).clamp(0, 255).toInt());
  }
}
