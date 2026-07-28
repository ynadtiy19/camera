import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 提供安全高效的加密解密本地缓存
class SecureStorageManager {
  SecureStorageManager._internal();

  static final SecureStorageManager _instance =
      SecureStorageManager._internal();

  static SecureStorageManager get instance => _instance;

  // 配置 Android 强制使用 EncryptedSharedPreferences (更安全)
  AndroidOptions _getAndroidOptions() =>
      const AndroidOptions(encryptedSharedPreferences: true);

  // 配置 iOS / macOS Keychain 策略
  IOSOptions _getIOSOptions() =>
      const IOSOptions(accessibility: KeychainAccessibility.first_unlock);

  late final FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: _getAndroidOptions(),
    iOptions: _getIOSOptions(),
  );

  static const String _keyAccessToken = 'access_token';
  static const String _keyBaseToken = 'base_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyUserId = 'user_id';
  static const String _keyDeviceUuid = 'device_uuid';
  static const String _keySavedCredentials = 'saved_credentials_list';

  /// 保存 Access Token
  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _keyAccessToken, value: token);
  }

  /// 获取 Access Token
  Future<String?> getAccessToken() async {
    return await _storage.read(key: _keyAccessToken);
  }

  /// 保存 Base Token (Supabase 兼容 Token)
  Future<void> saveBaseToken(String baseToken) async {
    await _storage.write(key: _keyBaseToken, value: baseToken);
  }

  /// 获取 Base Token
  Future<String?> getBaseToken() async {
    return await _storage.read(key: _keyBaseToken);
  }

  /// 保存 Refresh Token
  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _keyRefreshToken, value: token);
  }

  /// 获取 Refresh Token
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _keyRefreshToken);
  }

  /// 获取或自动创建本地设备唯一 UUID
  Future<String> getOrCreateDeviceUuid() async {
    String? uuid = await _storage.read(key: _keyDeviceUuid);
    if (uuid == null || uuid.isEmpty) {
      uuid = _generatePseudoUuid();
      await _storage.write(key: _keyDeviceUuid, value: uuid);
    }
    return uuid;
  }

  /// 生成伪 UUID (符合 8-4-4-4-12 规范)
  String _generatePseudoUuid() {
    final random = Random.secure();
    String hexString(int length) {
      final chars = '0123456789abcdef';
      return List.generate(length, (index) => chars[random.nextInt(16)]).join();
    }

    return '${hexString(8)}-${hexString(4)}-4${hexString(3)}-a${hexString(3)}-${hexString(12)}';
  }

  /// 读取所有已保存的账户密码凭据
  Future<List<Map<String, String>>> getSavedCredentials() async {
    try {
      final jsonStr = await _storage.read(key: _keySavedCredentials);
      if (jsonStr == null || jsonStr.isEmpty) return [];
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded.map((item) => Map<String, String>.from(item)).toList();
    } catch (e) {
      return [];
    }
  }

  /// 保存单条账户密码凭据（若存在则更新）
  Future<void> saveCredential(String username, String password) async {
    try {
      final list = await getSavedCredentials();
      list.removeWhere((item) => item['username'] == username);
      list.add({'username': username, 'password': password});
      await _storage.write(key: _keySavedCredentials, value: jsonEncode(list));
    } catch (_) {}
  }

  /// 删除单条账户密码凭据
  Future<void> deleteCredential(String username) async {
    try {
      final list = await getSavedCredentials();
      list.removeWhere((item) => item['username'] == username);
      await _storage.write(key: _keySavedCredentials, value: jsonEncode(list));
    } catch (_) {}
  }

  /// 保存普通字符串
  Future<void> saveString(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  /// 获取普通字符串
  Future<String?> getString(String key) async {
    return await _storage.read(key: key);
  }

  /// 删除某一项
  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  /// 清除 Token 凭证
  Future<void> clearTokens() async {
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyBaseToken);
    await _storage.delete(key: _keyRefreshToken);
    await _storage.delete(key: _keyUserId);
  }

  /// 清空所有数据
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
