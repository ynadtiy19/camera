import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../main/main_nav_view.dart';
import '../../services/app_login_service.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  @override
  void initState() {
    super.initState();
    _checkPrivacy();
  }

  /// 检查隐私协议同意状态
  Future<void> _checkPrivacy() async {
    final prefs = await SharedPreferences.getInstance();
    final hasAgreed = prefs.getBool('has_agreed_privacy') ?? false;

    if (!hasAgreed) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _showPrivacyDialog();
      });
    } else {
      _initSafeSDKsAndGo();
    }
  }

  /// 同意隐私协议后，全自动静默登录并跳转主页
  Future<void> _initSafeSDKsAndGo() async {
    try {
      // 自动提取原生硬件 UUID 并静默登录，卸载重装也能找回同一账号
      await AppLoginService.instance.silentLogin();
    } catch (e) {
      debugPrint("【SplashView】静默登录跳过或异常: $e");
    }

    // 展示过渡动画后平滑跳转至主页
    Future.delayed(const Duration(milliseconds: 1500), () {
      Get.offAll(
        () => const MainNavView(),
        transition: Transition.fadeIn,
        duration: const Duration(milliseconds: 800),
      );
    });
  }

  /// 隐私协议弹窗
  void _showPrivacyDialog() {
    Get.dialog(
      PopScope(
        canPop: false,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "服务协议与隐私政策",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      height: 1.5,
                    ),
                    children: [
                      TextSpan(text: "欢迎使用 匿名水印相机！在您使用前，请仔细阅读"),
                      TextSpan(
                        text: "《用户协议》",
                        style: TextStyle(color: Colors.blueAccent),
                      ),
                      TextSpan(text: "和"),
                      TextSpan(
                        text: "《隐私政策》",
                        style: TextStyle(color: Colors.blueAccent),
                      ),
                      TextSpan(text: "。我们将严格按照政策要求保护您的个人信息安全。"),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          if (Platform.isAndroid) {
                            SystemNavigator.pop();
                          } else {
                            exit(0);
                          }
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey,
                        ),
                        child: const Text("不同意"),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('has_agreed_privacy', true);
                          Get.back();
                          _initSafeSDKsAndGo();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text("同意并继续"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 1. 水印相机 Logo (图片居中)
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'images/splash.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: const Color(0xFFE8F0FE),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        size: 55,
                        color: Colors.blueAccent,
                      ),
                    );
                  },
                ),
              ),
            ).animate().fade(duration: 800.ms).scale(curve: Curves.easeOutBack),

            const SizedBox(height: 24),

            // 2. 标题文字
            const Text(
                  "匿名水印相机",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: Colors.black87,
                  ),
                )
                .animate()
                .fade(delay: 300.ms, duration: 600.ms)
                .slideY(begin: 0.3, end: 0),

            const SizedBox(height: 16),

            // 3. 加载点三连动画
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildDot(0),
                const SizedBox(width: 6),
                _buildDot(200),
                const SizedBox(width: 6),
                _buildDot(400),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int delayMs) {
    return Container(
          width: 5,
          height: 5,
          decoration: const BoxDecoration(
            color: Colors.grey,
            shape: BoxShape.circle,
          ),
        )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .fade(
          delay: Duration(milliseconds: delayMs),
          duration: 600.ms,
          begin: 0.2,
          end: 1.0,
        );
  }
}
