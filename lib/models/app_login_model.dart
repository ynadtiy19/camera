/// App 静默登录请求参数模型
class AppLoginRequest {
  final int appId;
  final String deviceUuid;
  final String? phone;
  final String? code;
  final String? platform;
  final String? brand;
  final String? model;

  AppLoginRequest({
    required this.appId,
    required this.deviceUuid,
    this.phone,
    this.code,
    this.platform,
    this.brand,
    this.model,
  });

  Map<String, dynamic> toJson() {
    return {
      'appId': appId,
      'deviceUuid': deviceUuid,
      if (phone != null) 'phone': phone,
      if (code != null) 'code': code,
      if (platform != null) 'platform': platform,
      if (brand != null) 'brand': brand,
      if (model != null) 'model': model,
    };
  }
}

/// 用户信息实体
class AppUserInfo {
  final int id;
  final String openId;

  AppUserInfo({required this.id, required this.openId});

  factory AppUserInfo.fromJson(Map<String, dynamic> json) {
    return AppUserInfo(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      openId: json['openId']?.toString() ?? '',
    );
  }
}

/// App 静默登录返回 Data 实体
class AppLoginData {
  final String token;
  final String baseToken;
  final AppUserInfo user;

  AppLoginData({
    required this.token,
    required this.baseToken,
    required this.user,
  });

  factory AppLoginData.fromJson(Map<String, dynamic> json) {
    return AppLoginData(
      token: json['token']?.toString() ?? '',
      baseToken: json['base_token']?.toString() ?? '',
      user: AppUserInfo.fromJson(json['user'] ?? {}),
    );
  }
}
