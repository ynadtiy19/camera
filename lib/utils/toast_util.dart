import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';

/// 完全基于 fluttertoast (FToast) 的 B站风格 (Bilibili Style) 中央高质感 Toast
class ToastUtil {
  ToastUtil._();

  static FToast? _fToast;

  /// 初始化并获取 fluttertoast 的 FToast 实例
  static FToast? _getFToast() {
    // 修正：GetX 中正确的导航 Key 属性为 Get.key
    final BuildContext? context = Get.context ?? Get.key.currentContext;
    if (context == null) return null;

    _fToast ??= FToast();
    _fToast!.init(context);
    return _fToast;
  }

  /// 通用/提示 (B站天蓝)
  static void show(String message) {
    _showToast(
      message: message,
      icon: Icons.info_outline_rounded,
      accentColor: const Color(0xFF23ADE5),
    );
  }

  /// 成功提示 (柔和翡翠绿)
  static void showSuccess(String message) {
    _showToast(
      message: message,
      icon: Icons.check_circle_outline_rounded,
      accentColor: const Color(0xFF34D399),
    );
  }

  /// 错误/警告提示 (柔和珊瑚红)
  static void showError(String message) {
    _showToast(
      message: message,
      icon: Icons.error_outline_rounded,
      accentColor: const Color(0xFFFF6B6B),
    );
  }

  /// 核心 FToast 自定义吐司弹出控制
  static void _showToast({
    required String message,
    required IconData icon,
    required Color accentColor,
  }) {
    if (message.trim().isEmpty) return;

    final FToast? fToast = _getFToast();
    if (fToast == null) return;

    // 弹出新提示前清除前一个 fluttertoast 吐司，避免堆叠
    fToast.removeCustomToast();

    fToast.showToast(
      child: _BilibiliToastWidget(
        message: message,
        icon: icon,
        accentColor: accentColor,
      ),
      gravity: ToastGravity.CENTER, // 屏幕居中
      toastDuration: const Duration(milliseconds: 1800),
      fadeDuration: const Duration(milliseconds: 220),
    );
  }
}

/// 结合 TweenAnimationBuilder 的 B站风格微缩放动画组件
class _BilibiliToastWidget extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color accentColor;

  const _BilibiliToastWidget({
    required this.message,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutBack,
      tween: Tween<double>(begin: 0.85, end: 1.0),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 260),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
            decoration: BoxDecoration(
              // B站暗黑磨砂底色 (#181820)
              color: const Color(0xE6181820),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.08),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: accentColor, size: 32),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                    letterSpacing: 0.2,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
