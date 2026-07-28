import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../services/app_login_service.dart';
import 'auth_state_manager.dart';
import 'secure_storage_manager.dart';

/// 请求挂起队列模型
class _QueuedRequest {
  final RequestOptions options;
  final ErrorInterceptorHandler handler;

  _QueuedRequest(this.options, this.handler);
}

/// Token 拦截与 401 无感静默重连状态锁
class AuthInterceptor extends Interceptor {
  final Dio dio;

  // 状态锁：判断是否正在通过静默登录刷新 Token
  bool _isRefreshing = false;

  // 挂起队列：静默重连期间的所有并发业务请求会被锁在这个队列中
  final List<_QueuedRequest> _queue = [];

  AuthInterceptor(this.dio);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // 每次发请求前注入最新的 Token
    final token = await SecureStorageManager.instance.getAccessToken();
    if (token != null && token.isNotEmpty) {
      // 根据文档说明 4：将 token 放入 Authorization 请求头（不带 Bearer 前缀，直接放 token 原文）
      options.headers['Authorization'] = token;
      // 兼顾旧接口需求保留 token 字段
      options.headers['token'] = token;
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // 捕获到 401 未授权错误，说明当前的 token 已过期 (超过 72 小时)
    if (err.response?.statusCode == 401) {
      // 如果当前没有在刷新，则开启【状态锁】，通过凭证静默重连换取新 Token
      if (!_isRefreshing) {
        _isRefreshing = true;
        bool isRefreshSuccess = false;

        // 【步骤一】发起静默登录重连
        try {
          debugPrint(
            "【AuthInterceptor】捕获到 401，正在通过 appId + deviceUuid 静默换取新 Token...",
          );
          isRefreshSuccess = await _performSilentReLogin();
        } catch (e) {
          debugPrint("【AuthInterceptor】静默换取 Token 异常: $e");
          isRefreshSuccess = false;
        }

        // 【步骤二】根据静默重连结果处理后续
        if (isRefreshSuccess) {
          debugPrint("【AuthInterceptor】静默登录成功！已获取全新的 72 小时 Token，重试挂起的请求。");
          final newToken = await SecureStorageManager.instance.getAccessToken();

          // 1. 重发当前失败的请求
          err.requestOptions.headers['Authorization'] = '$newToken';
          err.requestOptions.headers['token'] = '$newToken';
          try {
            final response = await dio.fetch(err.requestOptions);
            handler.resolve(response); // 成功拿到业务数据返回给上层
          } on DioException catch (retryErr) {
            handler.reject(retryErr);
          } catch (retryErr) {
            handler.reject(
              DioException(requestOptions: err.requestOptions, error: retryErr),
            );
          }

          // 2. 释放队列锁，依次重发排队中的并发请求
          for (var q in _queue) {
            q.options.headers['Authorization'] = '$newToken';
            q.options.headers['token'] = '$newToken';
            try {
              final res = await dio.fetch(q.options);
              q.handler.resolve(res);
            } on DioException catch (e) {
              q.handler.reject(e);
            } catch (e) {
              q.handler.reject(
                DioException(requestOptions: q.options, error: e),
              );
            }
          }
        } else {
          // 静默重连失败（如应用被禁用 Code 330 或网络断开），触发重置
          _triggerLogout(err, handler);
        }

        // 无论成功失败，释放状态锁并清空队列
        _isRefreshing = false;
        _queue.clear();
      } else {
        // 如果【状态锁】为 true (正在静默重连中)，新来的请求自动进入队列排队等待
        debugPrint("【AuthInterceptor】正在静默重连中，业务请求挂起排队...");
        _queue.add(_QueuedRequest(err.requestOptions, handler));
      }
      return;
    }

    // 非 401 错误，正常放行给外层处理
    handler.next(err);
  }

  /// 使用凭证静默重新登录 (POST /v1/api/app/login) 换取全新的 72 小时 Token
  Future<bool> _performSilentReLogin() async {
    try {
      // 直接调用 AppLoginService，它会自动获取真实的硬件设备 ID 并发起静默登录
      final loginData = await AppLoginService.instance.silentLogin();
      return loginData.token.isNotEmpty;
    } catch (e) {
      debugPrint("【AuthInterceptor】静默重新登录失败: $e");
      return false;
    }
  }

  /// 彻底失败时，清空凭证并告知状态管理器
  void _triggerLogout(DioException err, ErrorInterceptorHandler handler) {
    debugPrint("【AuthInterceptor】凭证彻底失效或无法连接服务，清除凭据。");
    AuthStateManager.instance.onTokenExpired();
    handler.next(err);
    // 拒绝队列里排队等待的所有请求
    for (var q in _queue) {
      q.handler.reject(
        DioException(requestOptions: q.options, error: "登录凭证已彻底失效，请重新连接网络"),
      );
    }
  }
}
