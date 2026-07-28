import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

import '../network/secure_storage_manager.dart';

/// 设备硬件信息提取工具类
class DeviceUtil {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// 获取系统原生硬件级设备 UUID (支持卸载重装保持一致)
  static Future<String> getUniqueDeviceUuid() async {
    try {
      if (!kIsWeb) {
        if (Platform.isAndroid) {
          final androidInfo = await _deviceInfo.androidInfo;
          // androidInfo.id 是 Android 8.0+ 系统硬件级别唯一标识 (ANDROID_ID)
          if (androidInfo.id.isNotEmpty) {
            return androidInfo.id;
          }
        } else if (Platform.isIOS) {
          final iosInfo = await _deviceInfo.iosInfo;
          // IDFV: 卸载重装后在同一开发者账号下保持不变
          if (iosInfo.identifierForVendor != null &&
              iosInfo.identifierForVendor!.isNotEmpty) {
            return iosInfo.identifierForVendor!;
          }
        }
      }
    } catch (e) {
      debugPrint("【DeviceUtil】获取系统原生硬件 ID 失败，降级使用加密存储 UUID: $e");
    }

    // 兜底方案：如果获取硬件原生 ID 失败，退回到读取/生成本地加密存储的固化 UUID
    return await SecureStorageManager.instance.getOrCreateDeviceUuid();
  }

  /// 获取当前运行平台类型 (如 iOS / Android)
  static String getPlatformName() {
    if (kIsWeb) return 'Web';
    return Platform.isIOS ? 'iOS' : 'Android';
  }

  /// 获取真实设备品牌 (如 Apple, HUAWEI, Xiaomi)
  static Future<String> getDeviceBrand() async {
    try {
      if (!kIsWeb) {
        if (Platform.isAndroid) {
          final androidInfo = await _deviceInfo.androidInfo;
          return androidInfo.brand;
        } else if (Platform.isIOS) {
          return 'Apple';
        }
      }
    } catch (_) {}
    return Platform.isIOS ? 'Apple' : 'Android';
  }

  /// 获取真实设备型号 (如 iPhone15,2 或 M2012K11C)
  static Future<String> getDeviceModel() async {
    try {
      if (!kIsWeb) {
        if (Platform.isAndroid) {
          final androidInfo = await _deviceInfo.androidInfo;
          return androidInfo.model;
        } else if (Platform.isIOS) {
          final iosInfo = await _deviceInfo.iosInfo;
          // 🌟 修复点：使用 utsname.machine 获取 iOS 设备型号
          return iosInfo.utsname.machine;
        }
      }
    } catch (_) {}
    return Platform.isIOS ? 'iPhone' : 'Android Device';
  }
}
