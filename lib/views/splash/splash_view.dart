import 'dart:io';

import 'package:flutter/gestures.dart';
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
    // 手势识别器（用于点击跳转纯文本条款页）
    final userAgreementRecognizer = TapGestureRecognizer()
      ..onTap = () {
        Get.to(
          () => const _PolicyDetailScreen(
            title: "用户协议",
            content: _userAgreementContent,
          ),
        );
      };

    final privacyPolicyRecognizer = TapGestureRecognizer()
      ..onTap = () {
        Get.to(
          () => const _PolicyDetailScreen(
            title: "隐私政策",
            content: _privacyPolicyContent,
          ),
        );
      };

    Get.dialog(
      PopScope(
        canPop: false, // 禁止返回键直接关闭弹窗
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 40,
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. 顶部 Header
                Container(
                  padding: const EdgeInsets.only(
                    top: 28,
                    left: 24,
                    right: 24,
                    bottom: 12,
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B).withOpacity(0.06),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.shield_outlined,
                          size: 28,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "服务协议与隐私政策",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. 中间可滚动的协议说明与权限概览
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 富文本提示语（包含可点击跳转纯文本页面的链接）
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                              height: 1.6,
                            ),
                            children: [
                              const TextSpan(text: "欢迎使用 "),
                              const TextSpan(
                                text: "匿答水印相机",
                                style: TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const TextSpan(text: "！在您使用前，请仔细阅读 "),
                              TextSpan(
                                text: "《用户协议》",
                                style: const TextStyle(
                                  color: Color(0xFF2563EB),
                                  fontWeight: FontWeight.w600,
                                ),
                                recognizer: userAgreementRecognizer,
                              ),
                              const TextSpan(text: " 和 "),
                              TextSpan(
                                text: "《隐私政策》",
                                style: const TextStyle(
                                  color: Color(0xFF2563EB),
                                  fontWeight: FontWeight.w600,
                                ),
                                recognizer: privacyPolicyRecognizer,
                              ),
                              const TextSpan(
                                text: "。点击“同意并继续”即代表您已充分阅读并接受上述条款。",
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // 核心权限收集说明卡片（合规要求）
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                              width: 0.8,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "主要权限与信息收集说明：",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF334155),
                                ),
                              ),
                              const SizedBox(height: 10),
                              _buildPermissionRow(
                                icon: Icons.location_on_outlined,
                                title: "位置权限",
                                desc: "获取实时地理位置，用于在照片中自动生成精准的定位水印",
                              ),
                              const SizedBox(height: 8),
                              _buildPermissionRow(
                                icon: Icons.camera_alt_outlined,
                                title: "相机与相册",
                                desc: "用于拍照添加水印及将生成的水印照片保存到系统相册",
                              ),
                              const SizedBox(height: 8),
                              _buildPermissionRow(
                                icon: Icons.smartphone_outlined,
                                title: "设备信息",
                                desc: "读取必要的设备标识以保证系统的稳定运行与适配",
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),
                        const Text(
                          "我们承诺严格按照相关法律法规保护您的隐私信息，绝不强制索权或违规收集数据。",
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 3. 底部操作按钮
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      // 不同意按钮
                      Expanded(
                        flex: 4,
                        child: OutlinedButton(
                          onPressed: () {
                            userAgreementRecognizer.dispose();
                            privacyPolicyRecognizer.dispose();
                            if (Platform.isAndroid) {
                              SystemNavigator.pop();
                            } else {
                              exit(0);
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF64748B),
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            "不同意",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // 同意并继续按钮
                      Expanded(
                        flex: 6,
                        child: ElevatedButton(
                          onPressed: () async {
                            userAgreementRecognizer.dispose();
                            privacyPolicyRecognizer.dispose();

                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setBool('has_agreed_privacy', true);

                            Get.back(); // 关闭弹窗
                            _initSafeSDKsAndGo(); // 执行静默登录并跳转主页
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F172A),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "同意并继续",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.54),
    );
  }

  /// 权限说明子行
  Widget _buildPermissionRow({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF475569)),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 11.5, height: 1.4),
              children: [
                TextSpan(
                  text: "$title：",
                  style: const TextStyle(
                    color: Color(0xFF334155),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(
                  text: desc,
                  style: const TextStyle(color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ),
      ],
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
                  'images/logo.jpeg',
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
                  "匿答水印相机",
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

// =============================================================================
// 纯原生 Flutter 条款详情展示页面（无需 Webview / HTML，直接原生 Widget 绘制）
// =============================================================================

class _PolicyDetailScreen extends StatelessWidget {
  final String title;
  final String content;

  const _PolicyDetailScreen({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: Color(0xFF0F172A),
          ),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SelectableText(
              content,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF334155),
                height: 1.8,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// 原生绘制文本（直接定义的内置服务条款与隐私政策文案）
// =============================================================================

const String _userAgreementContent = '''
《匿答水印相机 用户服务协议》

更新日期：2026年1月1日
生效日期：2026年1月1日

一、导言
欢迎使用“匿答水印相机”软件及相关服务（以下简称“本软件”）。本协议是您与本软件开发者之间关于使用本软件所订立的法律协议。

二、服务内容与使用规范
1. 本软件提供水印照片拍摄、时间与位置水印生成、水印保存与分享等功能。
2. 用户在使用本软件时，必须遵守国家法律法规，不得利用本软件制作、复制、发布、传播非法或侵权信息。
3. 您理解并同意，本软件生成的水印信息（如时间、位置等）仅供个人记录或工作拍照使用，用户应对其拍摄的内容独立承担法律责任。

三、知识产权声明
本软件包含的所有代码、界面设计、图标及文字内容的知识产权均归开发者所有。未经授权，任何单位或个人不得擅自复制、反编译或用于商业用途。

四、免责声明
1. 本软件按“现状”提供，开发者不保证软件服务一定能满足用户的全部需求，亦不保证服务的连续性与绝对无误。
2. 因不可抗力、网络原因或用户自身设备故障等原因导致的服务中断或数据丢失，开发者在法律允许范围内免责。

五、协议变更
开发者有权根据法律法规或产品升级需要变更本协议。修改后的协议一经公布即生效。
''';

const String _privacyPolicyContent = '''
《匿答水印相机 隐私政策》

更新日期：2026年1月1日
生效日期：2026年1月1日

匿答水印相机（以下简称“我们”）高度重视用户的隐私和个人信息保护。本政策将向您说明我们如何收集、使用及保护您的个人信息。

一、我们如何收集和使用您的个人信息
1. 位置信息：当您使用工作水印、定位水印功能时，我们需要申请获取您的【精确位置权限】（GPS），以便在拍照时实时注入经纬度和地理位置名称。位置信息仅在本地渲染水印，不会上传至第三方服务器。
2. 相机与相册权限：在您拍摄照片或保存生成的图像时，我们需要使用【相机权限】和【相册/存储权限】。
3. 设备信息：为保障应用的稳定运行及适配不同设备，我们可能会读取您的设备型号、操作系统版本等基本信息。

二、信息的保存与保护
1. 本软件定位为“匿答/本地水印工具”，您拍摄的所有照片及产生的水印数据均**保存在您的手机本地存储**中，我们不会将您的照片上传至网络服务器。
2. 我们采取合理的物理与技术安全措施保护您的信息，防止数据泄漏或被未经授权地访问。

三、对外提供与共享
我们不会将您的个人信息出售、出租或共享给任何无关的第三方公司、组织和个人。

四、您的权限管理
您可以在手机系统的“设置 - 权限管理”中随时开启或关闭位置、相机、存储等权限。关闭权限可能会影响对应功能（如定位水印）的使用，但不会影响其他基础功能。

五、如何联系我们
如您对本隐私政策有任何疑问、意见或建议，可通过应用内提供的反馈渠道与我们取得联系。
''';
