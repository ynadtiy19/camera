import 'package:flutter/foundation.dart';

import '../network/api_response.dart';
import '../network/http_client.dart';

/// 天气预报完整数据模型
class WeatherForecastData {
  final String locationName;
  final String region;
  final double tempC;
  final String conditionText;
  final String conditionIcon;
  final int humidity;
  final double windKph;
  final double maxTempC;
  final double minTempC;

  WeatherForecastData({
    required this.locationName,
    required this.region,
    required this.tempC,
    required this.conditionText,
    required this.conditionIcon,
    required this.humidity,
    required this.windKph,
    required this.maxTempC,
    required this.minTempC,
  });

  factory WeatherForecastData.fromJson(Map<String, dynamic> json) {
    final location = json['location'] as Map<String, dynamic>? ?? {};
    final current = json['current'] as Map<String, dynamic>? ?? {};
    final condition = current['condition'] as Map<String, dynamic>? ?? {};

    // 获取当天的预报数据
    final forecastList = json['forecast'] as List<dynamic>? ?? [];
    Map<String, dynamic> todayDay = {};
    if (forecastList.isNotEmpty) {
      final todayForecast = forecastList.first as Map<String, dynamic>? ?? {};
      todayDay = todayForecast['day'] as Map<String, dynamic>? ?? {};
    }

    return WeatherForecastData(
      locationName: location['name']?.toString() ?? '',
      region: location['region']?.toString() ?? '',
      tempC: (current['temp_c'] as num?)?.toDouble() ?? 0.0,
      conditionText: condition['text']?.toString() ?? '',
      conditionIcon: condition['icon']?.toString() ?? '',
      humidity: (current['humidity'] as num?)?.toInt() ?? 0,
      windKph: (current['wind_kph'] as num?)?.toDouble() ?? 0.0,
      maxTempC: (todayDay['maxtemp_c'] as num?)?.toDouble() ?? 0.0,
      minTempC: (todayDay['mintemp_c'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// 格式化用于水印显示的单行文字
  String toWatermarkString() {
    List<String> parts = [];
    if (conditionText.isNotEmpty) {
      parts.add(conditionText);
    }
    if (tempC > -100) {
      parts.add('${tempC.toStringAsFixed(1)}°C');
    }
    if (minTempC != 0.0 || maxTempC != 0.0) {
      parts.add(
        '(${minTempC.toStringAsFixed(1)}°C~${maxTempC.toStringAsFixed(1)}°C)',
      );
    }
    if (humidity > 0) {
      parts.add('湿度 $humidity%');
    }
    if (windKph > 0) {
      parts.add('风速 ${windKph.toStringAsFixed(1)}km/h');
    }
    return parts.join(' ');
  }
}

/// 天气网络请求服务类 (单例)
class WeatherService {
  WeatherService._internal();
  static final WeatherService instance = WeatherService._internal();

  WeatherForecastData? _lastForecast;
  WeatherForecastData? get lastForecast => _lastForecast;

  /// 请求天气预报接口 POST /mp/jd-haiba/weather/forecast
  Future<WeatherForecastData?> fetchWeatherForecast({
    required double latitude,
    required double longitude,
    int days = 3,
  }) async {
    try {
      final ApiResponse<dynamic> response = await HttpClient.instance.post(
        '/mp/jd-haiba/weather/forecast',
        data: {'latitude': latitude, 'longitude': longitude, 'days': days},
      );

      if (response.isSuccess && response.datas != null) {
        final data = response.datas;
        if (data is Map<String, dynamic>) {
          _lastForecast = WeatherForecastData.fromJson(data);
          debugPrint(
            "【WeatherService】天气预报获取成功: ${_lastForecast?.toWatermarkString()}",
          );
          return _lastForecast;
        }
      }
    } catch (e) {
      debugPrint("【WeatherService】天气预报请求异常: $e");
    }
    return null;
  }

  /// 一键获取格式化好的水印天气文字 summary
  Future<String> executeAndExportSummary({
    required double latitude,
    required double longitude,
  }) async {
    final forecast = await fetchWeatherForecast(
      latitude: latitude,
      longitude: longitude,
    );
    return forecast?.toWatermarkString() ?? '';
  }

  /// 请求真实海拔接口 POST /mp/jd-haiba/elevation
  Future<dynamic> getElevation(double latitude, double longitude) async {
    try {
      final ApiResponse<dynamic> response = await HttpClient.instance.post(
        '/mp/jd-haiba/elevation',
        data: {'latitude': latitude, 'longitude': longitude},
      );

      if (response.isSuccess && response.datas != null) {
        return response.datas; // 返回包含 {"elevation": 50} 的 Map 数据
      }
    } catch (e) {
      debugPrint("【WeatherService】海拔接口请求异常: $e");
    }
    return null;
  }

  /// 兼容补丁：获取当前天气
  Future<dynamic> getCurrentWeather(double lat, double lng) async {
    final forecast = await fetchWeatherForecast(latitude: lat, longitude: lng);
    if (forecast == null) return null;
    return {
      'location': {'name': forecast.locationName},
      'current': {
        'temp_c': forecast.tempC,
        'condition': {'text': forecast.conditionText},
      },
    };
  }
}
