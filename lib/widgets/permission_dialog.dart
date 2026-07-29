import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 高质感权限说明弹窗小部件
class PermissionDialog extends StatelessWidget {
  final String title;
  final String content;
  final VoidCallback onAllow;
  final VoidCallback? onDeny;

  const PermissionDialog({
    super.key,
    required this.title,
    required this.content,
    required this.onAllow,
    this.onDeny,
  });

  /// 快捷显示方法
  static Future<bool> show({
    required String title,
    required String content,
  }) async {
    final result = await Get.dialog<bool>(
      PermissionDialog(
        title: title,
        content: content,
        onAllow: () => Get.back(result: true),
        onDeny: () => Get.back(result: false),
      ),
      barrierDismissible: false,
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF6B46FE),
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '匿答水印相机 申请',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onAllow,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00B578), // 绿配色
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          '允许',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onDeny ?? () => Get.back(result: false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF2F3F5),
                          foregroundColor: const Color(0xFF00B578),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          '拒绝',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            right: 12,
            top: 12,
            child: IconButton(
              icon: const Icon(Icons.close, size: 18, color: Colors.black45),
              onPressed: () => Get.back(result: false),
            ),
          ),
        ],
      ),
    );
  }
}
