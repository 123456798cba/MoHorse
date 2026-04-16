import 'dart:async';
import 'package:flutter/material.dart';
import 'home_screen.dart';

/// 启动页 - 带宣传图
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    // 2.5秒后跳转到主页
    Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5F0EB);
    final accentColor = const Color(0xFF6C63FF);

    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              ),
            );
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo 区域
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accentColor,
                      accentColor.withValues(alpha: 0.6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    '🐴',
                    style: TextStyle(fontSize: 56),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // App 名称
              Text(
                'MoHorse清单',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF2D2D2D),
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),

              // Slogan
              Text(
                '记录每一天，管理每一笔',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white60 : const Color(0xFF999999),
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 48),

              // 功能亮点
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _FeatureChip(
                    icon: Icons.checklist_rtl_rounded,
                    label: '智能清单',
                    color: accentColor,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 16),
                  _FeatureChip(
                    icon: Icons.auto_awesome_rounded,
                    label: 'AI 录入',
                    color: const Color(0xFFFF6B6B),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 16),
                  _FeatureChip(
                    icon: Icons.receipt_long_rounded,
                    label: '轻松记账',
                    color: const Color(0xFF4ECDC4),
                    isDark: isDark,
                  ),
                ],
              ),
              const SizedBox(height: 60),

              // 加载指示器
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: accentColor.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;

  const _FeatureChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : const Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }
}
