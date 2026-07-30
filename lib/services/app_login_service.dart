import '../models/app_login_model.dart';
import '../network/api_response.dart';
import '../network/auth_state_manager.dart';
import '../network/http_client.dart';
import '../network/secure_storage_manager.dart';
import '../utils/device_util.dart';

/// 专门用于处理 水印相机 静默登录的服务类
class AppLoginService {
  AppLoginService._internal();

  static final AppLoginService _instance = AppLoginService._internal();

  static AppLoginService get instance => _instance;

  /// 执行静默登录 (全自动提取系统级唯一硬件信息)
  Future<AppLoginData> silentLogin() async {
    // 1. 获取系统硬件级 UUID (卸载重装依然保持一致)
    final deviceUuid = await DeviceUtil.getUniqueDeviceUuid();

    // 2. 自动获取平台、品牌与机型
    final platform = DeviceUtil.getPlatformName();
    final brand = await DeviceUtil.getDeviceBrand();
    final model = await DeviceUtil.getDeviceModel();

    // 3. 组装请求参数
    final requestBody = AppLoginRequest(
      appId: 2,
      deviceUuid: deviceUuid,
      platform: platform,
      brand: brand,
      model: model,
    );

    // 4. 发起网络请求 (POST /v1/api/app/login)
    final ApiResponse<dynamic> rawResponse = await HttpClient.instance.post(
      '/wx/v1/api/app/login',
      data: requestBody.toJson(),
    );

    // 5. 解析 Response Data 实体
    final loginData = AppLoginData.fromJson(
      rawResponse.datas as Map<String, dynamic>,
    );

    // 6. 保存生成的加密 Token 凭证
    await SecureStorageManager.instance.saveAccessToken(loginData.token);
    await SecureStorageManager.instance.saveBaseToken(loginData.baseToken);

    // 7. 标记为已登录状态
    AuthStateManager.instance.onLoginSuccess();

    // VisitTrackingService.instance.startTracking();

    return loginData;
  }
}
