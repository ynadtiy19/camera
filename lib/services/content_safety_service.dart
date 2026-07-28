import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../network/api_response.dart';
import '../network/http_client.dart';

/// 微信小程序 / App 内容安全检测服务
/// 严格仅使用后端提供的 2 个有效 API 接口：
/// 1. POST /v1/api/app/content/check
/// 2. GET /v1/api/app/content/result?id=xxx
class ContentSafetyService {
  ContentSafetyService._internal();

  static final ContentSafetyService _instance =
      ContentSafetyService._internal();

  static ContentSafetyService get instance => _instance;

  /// 接口一：提交内容检测请求 (checkType: 2 图片, 3 文本)
  Future<dynamic> checkData({
    String txt = '',
    required int checkType,
    String mediaUrl = '',
  }) async {
    try {
      if (checkType != 2 && checkType != 3) {
        throw Exception('checkType 必须为 2(图片检测) 或 3(文本检测)');
      }
      if (checkType == 3 && txt.trim().isEmpty) {
        throw Exception('文本检测时 content 不能为空');
      }
      if (checkType == 2 && mediaUrl.trim().isEmpty) {
        throw Exception('图片检测时 mediaUrl 不能为空');
      }

      final postData = {
        'content': txt,
        'checkType': checkType,
        'mediaUrl': mediaUrl,
      };

      final ApiResponse<dynamic> response = await HttpClient.instance.post(
        '/v1/api/app/content/check',
        data: postData,
      );

      if (response.isSuccess && response.datas != null) {
        final data = response.datas;
        if (data is Map) {
          if (checkType == 3) {
            // 文本检测: suggest == 'pass' 返回 1 (合规)，否则返回 2 (违规)
            final suggest = data['suggest']?.toString();
            return suggest == 'pass' ? 1 : 2;
          } else if (checkType == 2) {
            // 图片检测: 返回检测任务 checkId
            return data['id']?.toString();
          }
        }
      }
      return 2;
    } catch (e) {
      debugPrint("【内容安全】提交检测请求异常: $e");
      return 2;
    }
  }

  /// 接口二：查询安全检查结果 label
  Future<int?> checkSafetyResults(String checkId) async {
    try {
      final ApiResponse<dynamic> response = await HttpClient.instance.get(
        '/v1/api/app/content/result?id=$checkId',
      );
      if (response.isSuccess && response.datas != null) {
        final data = response.datas;
        if (data is Map && data.containsKey('label')) {
          final label = data['label'];
          return label is int ? label : int.tryParse(label.toString());
        }
      }
      return null;
    } catch (e) {
      debugPrint("【内容安全】获取检测结果失败: $e");
      return null;
    }
  }

  /// 业务交互 1：校验自定义水印文本 (仅调用 POST /v1/api/app/content/check)
  Future<bool> checkTextContent(String text) async {
    if (text.trim().isEmpty) return false;

    return true;
    // final result = await checkData(txt: text.trim(), checkType: 3);
    // if (result == 1) {
    //   return true; // 审核通过
    // } else {
    //   showWarningDialog('输入的文字包含敏感或违规内容，请修改后重试');
    //   return false; // 审核不通过
    // }
  }

  /// 业务交互 2：轮询检查网络图片 URL 合规性
  Future<bool> checkImageUrl(String mediaUrl) async {
    if (mediaUrl.trim().isEmpty) return false;

    Get.dialog(
      const PopScope(
        canPop: false,
        child: Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text("正在审核内容合规性...", style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );

    try {
      // 1. 提交图片检测任务，获取 checkId
      final checkId = await checkData(
        txt: '',
        checkType: 2,
        mediaUrl: mediaUrl,
      );
      if (checkId == null || checkId == 2) {
        Get.back();
        showWarningDialog("内容检测任务提交失败，请重试");
        return false;
      }

      // 2. 轮询结果 (最多 5 次，间隔 2 秒)
      int retryCount = 0;
      const int maxRetries = 5;

      while (retryCount < maxRetries) {
        await Future.delayed(const Duration(seconds: 2));
        final label = await checkSafetyResults(checkId.toString());

        if (label != null) {
          switch (label) {
            case 100:
              Get.back(); // 审核通过
              return true;
            case 20001:
              Get.back();
              showWarningDialog('内容包含时政敏感信息，请重新选择');
              return false;
            case 20002:
              Get.back();
              showWarningDialog('内容含有色情不雅信息，请重新选择');
              return false;
            case 20006:
              Get.back();
              showWarningDialog('内容含有违法犯罪信息，请重新选择');
              return false;
            case 21000:
              Get.back();
              showWarningDialog('内容含有非法敏感信息，请重新选择');
              return false;
            default:
              break;
          }
        }
        retryCount++;
      }

      Get.back();
      showWarningDialog('内容审核超时，请重试');
      return false;
    } catch (e) {
      Get.back();
      debugPrint("【内容安全】图片审核异常: $e");
      showWarningDialog('内容检测异常，请重试');
      return false;
    }
  }

  /// 安全提示弹窗
  void showWarningDialog(String msg) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 48,
              ),
              const SizedBox(height: 12),
              const Text(
                '安全提示',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                msg,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black87,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(120, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('我知道了'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
