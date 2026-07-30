import 'dart:async';

import 'package:flutter/foundation.dart';

import '../network/http_client.dart';

/// 应用访问埋点与心跳服务
class VisitTrackingService {
  VisitTrackingService._internal();

  static final VisitTrackingService _instance =
      VisitTrackingService._internal();

  static VisitTrackingService get instance => _instance;

  Timer? _timer;

  DateTime? _lastReportTime;

  /// 用户点击屏幕时触发上报 (10 秒节流保护，避免连续猛点刷接口)
  void reportOnUserInteraction() {
    final now = DateTime.now();
    if (_lastReportTime == null ||
        now.difference(_lastReportTime!) > const Duration(seconds: 10)) {
      _lastReportTime = now;
      sendVisitPing();
      debugPrint("【埋点服务】检测到用户触摸屏幕，触发 10s 节流上报");
    }
  }

  /// 开启定时访问埋点上报 (默认每 2 分钟上报一次)
  void startTracking({Duration interval = const Duration(seconds: 10)}) {
    // 1. 避免重复创建定时器
    _timer?.cancel();

    // 2. 登录成功后立即上报第 1 次
    sendVisitPing();

    // 3. 开启心跳轮询上报
    _timer = Timer.periodic(interval, (_) {
      sendVisitPing();
    });
    debugPrint("【埋点服务】已开启定时轮询 (间隔: ${interval.inSeconds}秒)");
  }

  /// 停止埋点上报 (登出/Token 失效时调用)
  void stopTracking() {
    _timer?.cancel();
    _timer = null;
    debugPrint("【埋点服务】已停止定时轮询");
  }

  /// 发送访问埋点请求 (POST /wx/v1/api/visit)
  Future<void> sendVisitPing() async {
    try {
      // 请求会通过 HttpClient 拦截器自动携带最新的 Authorization Header
      await HttpClient.instance.post('/wx/v1/api/visit', data: {});
      debugPrint("【埋点服务】访问埋点上报成功");
    } catch (e) {
      debugPrint("【埋点服务】上报失败或网络异常: $e");
    }
  }
}
