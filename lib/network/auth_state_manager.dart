import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../main/main_nav_view.dart';
import '../services/visit_tracking_service.dart';
import 'secure_storage_manager.dart';

/// 用户的三种模式：游客、已登录、登录过期
enum AuthMode { guest, loggedIn, expired }

/// 负责维护全局登录状态以及路由跳转扩展
class AuthStateManager {
  // 单例模式
  AuthStateManager._internal();

  static final AuthStateManager _instance = AuthStateManager._internal();

  static AuthStateManager get instance => _instance;

  /// 当前用户状态监听器
  final ValueNotifier<AuthMode> authModeNotifier = ValueNotifier(
    AuthMode.guest,
  );

  AuthMode get currentMode => authModeNotifier.value;

  /// 初始化应用时检查状态
  Future<void> checkInitialState() async {
    final token = await SecureStorageManager.instance.getAccessToken();
    if (token != null && token.isNotEmpty) {
      authModeNotifier.value = AuthMode.loggedIn;
    } else {
      authModeNotifier.value = AuthMode.guest;
    }
  }

  /// 成功登录后调用
  void onLoginSuccess() {
    authModeNotifier.value = AuthMode.loggedIn;
  }

  /// Token 彻底过期或刷新失败时调用 (由于登录页可选，直接清空状态并平滑重定向回主页)
  Future<void> onTokenExpired() async {
    VisitTrackingService.instance.stopTracking();

    authModeNotifier.value = AuthMode.expired;
    await SecureStorageManager.instance.clearTokens();

    debugPrint("【AuthStateManager】检测到登录过期，自动重置凭据并返回主页。");

    Get.offAll(() => const MainNavView(), transition: Transition.fadeIn);
  }

  /// 用户主动退出登录
  Future<void> logout() async {
    VisitTrackingService.instance.stopTracking();

    await SecureStorageManager.instance.clearTokens();
    authModeNotifier.value = AuthMode.guest;

    debugPrint("【AuthStateManager】用户登出完毕，重定向至主页。");

    Get.offAll(() => const MainNavView(), transition: Transition.fadeIn);
  }
}
