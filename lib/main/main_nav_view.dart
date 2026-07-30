import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/api_response.dart';
import '../network/http_client.dart';
import '../utils/app_web_view_page.dart';
import '../utils/toast_util.dart';
import '../views/photo_editor/photo_editor_controller.dart';
import '../views/photo_editor/photo_editor_view.dart';
import '../widgets/permission_dialog.dart';

/// 全局跳转至编辑页面方法
void openPhotoEditor(String localImagePath) {
  Get.to(
    () => const PhotoEditorView(),
    binding: BindingsBuilder(() {
      Get.lazyPut<PhotoEditorController>(() => PhotoEditorController());
    }),
    arguments: localImagePath,
  );
}

/// 匿答水印相机 - 单页面应用主界面
class MainNavView extends StatelessWidget {
  const MainNavView({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return '早上好';
    if (hour < 18) return '下午好';
    return '晚上好';
  }

  String _getDateString() {
    final now = DateTime.now();
    final weekDays = ['日', '一', '二', '三', '四', '五', '六'];
    return '${now.month}月${now.day}日 星期${weekDays[now.weekday % 7]}';
  }

  /// 拍摄照片（仅在初次时弹出权限预说明）
  Future<void> _takePhoto() async {
    final prefs = await SharedPreferences.getInstance();
    final hasPromptedCamera =
        prefs.getBool('has_prompted_camera_permission') ?? false;

    if (!hasPromptedCamera) {
      final allow = await PermissionDialog.show(
        title: '使用摄像头拍摄照片',
        content: '需要调用系统相机进行即时拍摄，以便为你生成带有定位与水印的光影照片。',
      );
      if (!allow) return;
      await prefs.setBool('has_prompted_camera_permission', true);
    }

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 95,
      );
      if (photo != null && photo.path.isNotEmpty) {
        openPhotoEditor(photo.path);
      }
    } catch (_) {
      ToastUtil.showError('无法调起系统相机，请检查设置');
    }
  }

  /// 相册选图（仅在初次未授权时弹出权限预说明）
  Future<void> _pickFromGallery() async {
    bool hasAccess = false;
    try {
      hasAccess = await Gal.hasAccess();
    } catch (_) {}

    if (!hasAccess) {
      final prefs = await SharedPreferences.getInstance();
      final hasPromptedGallery =
          prefs.getBool('has_prompted_gallery_permission') ?? false;

      if (!hasPromptedGallery) {
        final allow = await PermissionDialog.show(
          title: '读取相册中的图片',
          content: '需要访问相册，以便选择你需要添加滤镜和水印的现有图片。',
        );
        if (!allow) return;
        await prefs.setBool('has_prompted_gallery_permission', true);
      }
    }

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 95,
      );
      if (image != null && image.path.isNotEmpty) {
        openPhotoEditor(image.path);
      }
    } catch (_) {
      ToastUtil.showError('无法读取相册，请检查相关权限');
    }
  }

  /// 动态异步获取微信号并展示“联系作者”对话框
  void _showContactDialog() {
    String kfWx = '加载中...';
    bool isLoading = true;

    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          // 异步请求微信号接口
          Future<void> fetchKfWx() async {
            try {
              // 请求 GET https://ca.wxshot.cn/wx/v1/api/echo
              final ApiResponse<dynamic> response = await HttpClient.instance
                  .get('/wx/v1/api/echo');

              if (response.isSuccess && response.datas != null) {
                final data = response.datas;
                if (data is Map &&
                    data.containsKey('kfWx') &&
                    data['kfWx'] != null) {
                  final String fetchedWx = data['kfWx'].toString();
                  if (fetchedWx.isNotEmpty) {
                    setState(() {
                      kfWx = fetchedWx;
                      isLoading = false;
                    });
                    return;
                  }
                }
              }

              // 如果接口未返回 kfWx，使用默认值兜底
              setState(() {
                kfWx = '获取出错';
                isLoading = false;
              });
            } catch (e) {
              debugPrint("【联系作者】获取微信号失败，使用默认值: $e");
              setState(() {
                kfWx = '获取出错';
                isLoading = false;
              });
            }
          }

          // 弹窗首次渲染时自动发起 API 请求
          if (isLoading && kfWx == '加载中...') {
            fetchKfWx();
          }

          return Dialog(
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
                    '联系作者',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '微信号',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  // 微信号动态展示区域
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF10B981),
                              ),
                            )
                          : Text(
                              kfWx,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF10B981),
                                letterSpacing: 1,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isLoading || kfWx == '加载中...'
                              ? null
                              : () {
                                  Clipboard.setData(ClipboardData(text: kfWx));
                                  Get.back();
                                  ToastUtil.showSuccess('内容已复制');
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: const Text(
                            '复制微信号',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextButton(
                          onPressed: () => Get.back(),
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFFF3F4F6),
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: const Text(
                            '关闭',
                            style: TextStyle(fontSize: 15),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _shareApp() {
    // WeatherService.instance.executeAndExportSummary(latitude: null, longitude: null);

    Share.share(
      '推荐一个好用的匿答水印相机 App，支持滤镜修图与智能水印！点击下载体验：https://camera.wtminiapp.com',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('匿答水印相机'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      backgroundColor: const Color(0xFFF6F7FB),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 1. 紫色浪漫渐变 Hero 卡片
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Color(0xFF6643FE), Color(0xFF9B52FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6643FE).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _getGreeting(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _getDateString(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '记录此刻的光影',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: _takePhoto,
                      icon: Image.asset(
                        'images/cam_hero.png',
                        width: 20,
                        height: 20,
                        // 如果你的图片是单色图标且需要叠加白色，可以取消下面这行的注释：
                        // color: Colors.white,
                      ),
                      label: const Text(
                        '开始拍摄',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: Colors.white.withOpacity(0.6),
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 2. 快捷按钮行
            Row(
              children: [
                _buildSquareButton(
                  imagePath: 'images/zuozhe.png',
                  label: '联系作者',
                  onTap: _showContactDialog,
                ),
                const SizedBox(width: 12),
                _buildSquareButton(
                  imagePath: 'images/share.png',
                  label: '分享朋友',
                  onTap: _shareApp,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 3. 相册修图卡片
            Card(
              elevation: 0,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: Colors.white,
              child: ListTile(
                onTap: _pickFromGallery,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Image.asset(
                    'images/edit_photo.png',
                    width: 28,
                    height: 28,
                  ),
                ),
                title: const Text(
                  '相册修图',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  '从相册选一张照片，加滤镜和水印',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 4. 小贴士卡片
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '小贴士',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildTipItem('拍照页支持前后置拍摄与延时自拍'),
                    _buildTipItem('编辑页可叠加复古、胶片等 8 款滤镜'),
                    _buildTipItem('水印自定义选择时间，经纬度，海拔，设备型号等'),
                    _buildTipItem('成片可直接分享给微信，QQ好友'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 5. 底部版权与协议跳转区域
            Padding(
              padding: const EdgeInsets.only(bottom: 24, top: 8),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 用户协议
                      GestureDetector(
                        onTap: () {
                          Get.to(
                            () => const AppWebViewPage(
                              title: '用户协议',
                              url:
                                  'https://camera.wtminiapp.com/user_agreement.html',
                            ),
                          );
                        },
                        child: const Text(
                          '用户协议',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.underline,
                            decorationColor: Color(0xFF64748B),
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          '|',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFFCBD5E1),
                          ),
                        ),
                      ),
                      // 隐私政策
                      GestureDetector(
                        onTap: () {
                          Get.to(
                            () => const AppWebViewPage(
                              title: '隐私政策',
                              url:
                                  'https://camera.wtminiapp.com/privacy_policy.html',
                            ),
                          );
                        },
                        child: const Text(
                          '隐私政策',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.underline,
                            decorationColor: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Copyright © 2026 匿答水印相机 All Rights Reserved',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSquareButton({
    required String imagePath,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Image.asset(imagePath, width: 24, height: 24),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(
              color: Color(0xFF6366F1),
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
