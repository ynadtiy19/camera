import 'dart:io';
import 'dart:ui' as ui;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../services/content_safety_service.dart';
import '../../services/weather_service.dart';
import '../../utils/toast_util.dart';
import '../../widgets/permission_dialog.dart';
import 'widgets/custom_watermark_dialog.dart';

class FilterModel {
  final String key;
  final String name;
  final List<double> matrix;

  const FilterModel({
    required this.key,
    required this.name,
    required this.matrix,
  });
}

class PhotoEditorController extends GetxController {
  late String imagePath;

  final RxString activeTab = 'filter'.obs;
  final RxString filterKey = 'original'.obs;

  // 图片物理宽高比 (用于解决 UI 错位与黑边漂浮问题)
  final RxDouble imageAspectRatio = (4.0 / 3.0).obs;

  // 使用 RxMap 配合 refresh() 保证全局高亮控制灵敏
  final RxMap<String, bool> wmFields = <String, bool>{
    'time': false,
    'geo': false,
    'altitude': false,
    'device': false,
    'custom': false,
  }.obs;

  final RxString customText = ''.obs;
  final RxBool isSaving = false.obs;

  Position? position;
  String deviceModelStr = '';
  String timeStr = '';
  String dateWeekStr = '';

  // 从 API 接口获取的实时数据
  String weatherText = '';
  String locationName = '';
  double? apiElevation;

  final List<FilterModel> filters = const [
    FilterModel(
      key: 'original',
      name: '原图',
      matrix: [1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0],
    ),
    FilterModel(
      key: 'fresh',
      name: '清新',
      matrix: [
        0.92,
        0,
        0,
        0,
        12,
        0,
        0.92,
        0,
        0,
        14,
        0,
        0,
        0.92,
        0,
        12,
        0,
        0,
        0,
        1,
        0,
      ],
    ),
    FilterModel(
      key: 'vivid',
      name: '鲜艳',
      matrix: [
        1.3,
        0,
        0,
        0,
        -10,
        0,
        1.3,
        0,
        0,
        -10,
        0,
        0,
        1.3,
        0,
        -10,
        0,
        0,
        0,
        1,
        0,
      ],
    ),
    FilterModel(
      key: 'mono',
      name: '黑白',
      matrix: [
        0.299,
        0.587,
        0.114,
        0,
        0,
        0.299,
        0.587,
        0.114,
        0,
        0,
        0.299,
        0.587,
        0.114,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
      ],
    ),
    FilterModel(
      key: 'sepia',
      name: '复古',
      matrix: [
        0.393,
        0.769,
        0.189,
        0,
        0,
        0.349,
        0.686,
        0.168,
        0,
        0,
        0.272,
        0.534,
        0.131,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
      ],
    ),
    FilterModel(
      key: 'film',
      name: '胶片',
      matrix: [
        0.85,
        0.05,
        0.05,
        0,
        16,
        0.05,
        0.88,
        0.05,
        0,
        18,
        0.05,
        0.05,
        0.82,
        0,
        22,
        0,
        0,
        0,
        1,
        0,
      ],
    ),
    FilterModel(
      key: 'cool',
      name: '冷调',
      matrix: [
        0.9,
        0,
        0,
        0,
        -12,
        0,
        0.9,
        0,
        0,
        0,
        0,
        0,
        1.1,
        0,
        20,
        0,
        0,
        0,
        1,
        0,
      ],
    ),
    FilterModel(
      key: 'warm',
      name: '暖调',
      matrix: [
        1.1,
        0,
        0,
        0,
        20,
        0,
        1.0,
        0,
        0,
        6,
        0,
        0,
        0.85,
        0,
        -14,
        0,
        0,
        0,
        1,
        0,
      ],
    ),
  ];

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments != null && Get.arguments is String) {
      imagePath = Get.arguments as String;
    } else {
      imagePath = '';
    }
    _initTimeAndDevice();
    _loadImageAspectRatio();
    _autoInitDataAndFetchApi();
  }

  /// 🌟 自动解析原图尺寸并计算物理宽高比
  Future<void> _loadImageAspectRatio() async {
    if (imagePath.isEmpty || !File(imagePath).existsSync()) return;
    try {
      final File file = File(imagePath);
      final Uint8List bytes = await file.readAsBytes();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final double w = frameInfo.image.width.toDouble();
      final double h = frameInfo.image.height.toDouble();
      if (h > 0) {
        imageAspectRatio.value = w / h;
      }
    } catch (e) {
      debugPrint("【PhotoEditorController】读取图片宽高比失败: $e");
    }
  }

  Future<void> _initTimeAndDevice() async {
    final now = DateTime.now();
    final weekDays = ['日', '一', '二', '三', '四', '五', '六'];
    dateWeekStr =
        '${DateFormat('yyyy-MM-dd').format(now)} 周${weekDays[now.weekday % 7]}';
    timeStr = DateFormat('HH:mm:ss').format(now);

    try {
      final deviceInfo = DeviceInfoPlugin();
      if (!kIsWeb) {
        if (Platform.isAndroid) {
          final androidInfo = await deviceInfo.androidInfo;
          deviceModelStr = '${androidInfo.brand} ${androidInfo.model}';
        } else if (Platform.isIOS) {
          final iosInfo = await deviceInfo.iosInfo;
          deviceModelStr = 'Apple ${iosInfo.model}';
        }
      }
    } catch (_) {
      deviceModelStr = 'Mobile Device';
    }
  }

  /// 进入编辑页自动调用定位与海拔/天气 API
  Future<void> _autoInitDataAndFetchApi() async {
    final hasLocation = await _ensureLocation();

    if (hasLocation && position != null) {
      wmFields['time'] = true;
      wmFields['geo'] = true;
      wmFields['altitude'] = true;
      wmFields['device'] = true;
      wmFields.refresh();

      try {
        final lat = position!.latitude;
        final lng = position!.longitude;

        final elevationRes = await WeatherService.instance.getElevation(
          lat,
          lng,
        );
        if (elevationRes is Map && elevationRes['elevation'] != null) {
          apiElevation = double.tryParse(elevationRes['elevation'].toString());
        }

        final forecastSummary = await WeatherService.instance
            .executeAndExportSummary(latitude: lat, longitude: lng);

        if (forecastSummary.isNotEmpty) {
          weatherText = forecastSummary;
        }

        wmFields.refresh();
      } catch (e) {
        debugPrint("【PhotoEditorController】海拔/天气 API 请求异常: $e");
      }
    } else {
      wmFields['time'] = true;
      wmFields['device'] = true;
      wmFields.refresh();
    }
  }

  void switchTab(String tab) {
    activeTab.value = tab;
  }

  void selectFilter(String key) {
    filterKey.value = key;
  }

  /// 切换水印字段状态
  Future<void> toggleWatermarkField(String key) async {
    final curState = wmFields[key] ?? false;
    final newState = !curState;

    if (key == 'custom' && newState) {
      final result = await Get.dialog<String>(
        CustomWatermarkDialog(initialText: customText.value),
      );
      if (result != null && result.trim().isNotEmpty) {
        final pass = await ContentSafetyService.instance.checkTextContent(
          result.trim(),
        );
        if (pass) {
          customText.value = result.trim();
          wmFields[key] = true;
        } else {
          wmFields[key] = false;
        }
      } else if (customText.value.isEmpty) {
        wmFields[key] = false;
      }
      wmFields.refresh();
      return;
    }

    if (newState && (key == 'geo' || key == 'altitude')) {
      final ok = await _ensureLocation();
      if (!ok) return;
    }

    wmFields[key] = newState;
    wmFields.refresh();
  }

  /// 🌟 高质感引导用户跳转系统设置页的弹窗小部件
  Future<bool> _showAppSettingsDialog({
    required String title,
    required String content,
    required String confirmText,
  }) async {
    final result = await Get.dialog<bool>(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 320),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 24,
                spreadRadius: 0,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. 顶部暖橙色柔光渐变图标徽章
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFFF3E0),
                      const Color(0xFFFFE0B2).withOpacity(0.6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.18),
                      blurRadius: 16,
                      spreadRadius: 2,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.location_off_rounded,
                    color: Color(0xFFFF9200), // 温暖主亮橙
                    size: 34,
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // 2. 主标题
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1D1E2C),
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 10),

              // 3. 正文描述（舒适行高与配色）
              Text(
                content,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: Color(0xFF6E7191),
                  height: 1.5,
                  letterSpacing: 0.1,
                ),
              ),
              const SizedBox(height: 24),

              // 4. 底部双弹按钮行
              Row(
                children: [
                  // 取消按键
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: TextButton(
                        onPressed: () => Get.back(result: false),
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFF3F4F8),
                          foregroundColor: const Color(0xFF6E7191),
                          elevation: 0,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(23),
                          ),
                        ),
                        child: const Text(
                          '取消',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 主确认/去设置按键（带紫色紫光阴影）
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: ElevatedButton(
                        onPressed: () => Get.back(result: true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B5CF6),
                          foregroundColor: Colors.white,
                          elevation: 4,
                          shadowColor: const Color(0xFF8B5CF6).withOpacity(0.4),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(23),
                          ),
                        ),
                        child: Text(
                          confirmText,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
    return result ?? false;
  }

  /// 请求定位权限（深度适配小米 HyperOS / MIUI 无谷歌服务环境）
  Future<bool> _ensureLocation() async {
    if (position != null) return true;

    try {
      // 1. 检查手机系统的 GPS 总开关（下拉控制中心里的位置信息）
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        final openGps = await _showAppSettingsDialog(
          title: '手机 GPS 总开关未开启',
          content: '你已为应用开启权限，但手机系统的【位置信息/GPS】总开关尚未开启。请在下拉控制中心或设置中开启。',
          confirmText: '去开启 GPS 开关',
        );
        if (openGps) {
          await Geolocator.openLocationSettings(); // 跳转至系统 GPS 开关页
        }
        return false;
      }

      // 2. 检查应用权限
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        final allow = await PermissionDialog.show(
          title: '获取你的精确地理位置',
          content: '用于在照片水印中自动标注当前拍摄地的经纬度与海拔高度信息。',
        );
        if (!allow) return false;

        permission = await Geolocator.requestPermission();
      }

      // 3. 处理权限被拒绝/不再弹窗的情况
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        final openSettings = await _showAppSettingsDialog(
          title: '需要定位权限',
          content: '检测到应用定位权限未生效。请在系统“权限管理”中将“获取位置信息”设置为【仅在使用中允许】。',
          confirmText: '去系统设置开启',
        );
        if (openSettings) {
          await Geolocator.openAppSettings(); // 跳转至小米应用权限设置页
        }
        return false;
      }

      // 4. 优先读取最后一次已知位置（秒级响应，避免无信号死等）
      Position? lastPos = await Geolocator.getLastKnownPosition();
      if (lastPos != null) {
        position = lastPos;
        return true;
      }

      // 🌟 5. 核心突破：国产手机（小米/华为/OPPO/vivo）强制指定 forceLocationManager: true
      // 避开谷歌服务死锁，直接调用 Android 原生 LocationManager
      late LocationSettings locationSettings;

      if (defaultTargetPlatform == TargetPlatform.android) {
        locationSettings = AndroidSettings(
          accuracy: LocationAccuracy.medium,
          forceLocationManager: true, // 强制绕过谷歌 GMS 服务！
          timeLimit: const Duration(seconds: 5),
        );
      } else {
        locationSettings = const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 5),
        );
      }

      position = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );
      return true;
    } catch (e) {
      debugPrint("【小米定位异常】: $e");
      ToastUtil.show('暂未获取到 GPS 信号，已开启基础位置标注');
      return false;
    }
  }

  List<double> get activeMatrix {
    final item = filters.firstWhere(
      (f) => f.key == filterKey.value,
      orElse: () => filters.first,
    );
    return item.matrix;
  }

  /// 绘制成片（确保高分辨率与中央 Logo + 左下角水印完整导出）
  Future<Uint8List?> renderExportBytes() async {
    if (imagePath.isEmpty || !File(imagePath).existsSync()) return null;

    final File imageFile = File(imagePath);
    final Uint8List originBytes = await imageFile.readAsBytes();

    final ui.Codec codec = await ui.instantiateImageCodec(originBytes);
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    final ui.Image originImage = frameInfo.image;

    final double width = originImage.width.toDouble();
    final double height = originImage.height.toDouble();

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width, height));

    // 1. 绘制带有滤镜矩阵的底图
    final Paint filterPaint = Paint()
      ..colorFilter = ColorFilter.matrix(activeMatrix);
    canvas.drawImage(originImage, Offset.zero, filterPaint);

    // 2. 绘制正中央固定半透明“匿答水印相机”推广 Logo
    _drawCenterLogo(canvas, width, height);

    // 3. 绘制左下角排版水印
    _drawWatermarkStamps(canvas, width, height);

    final ui.Picture picture = recorder.endRecording();
    final ui.Image finalImage = await picture.toImage(
      width.toInt(),
      height.toInt(),
    );
    final ByteData? byteData = await finalImage.toByteData(
      format: ui.ImageByteFormat.png,
    );

    return byteData?.buffer.asUint8List();
  }

  void _drawCenterLogo(Canvas canvas, double w, double h) {
    final double minSide = w < h ? w : h;
    final double logoFontSize = (minSide * 0.075).clamp(32.0, 180.0);

    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: '匿答水印相机',
        style: TextStyle(
          color: Colors.white.withOpacity(0.28),
          fontSize: logoFontSize,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
          letterSpacing: logoFontSize * 0.15,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.35),
              offset: Offset(minSide * 0.003, minSide * 0.003),
              blurRadius: minSide * 0.008,
            ),
          ],
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );

    tp.layout();
    final double x = (w - tp.width) / 2;
    final double y = (h - tp.height) / 2;
    tp.paint(canvas, Offset(x, y));
  }

  void _drawWatermarkStamps(Canvas canvas, double w, double h) {
    final List<String> lines = [];

    String formatLat(double lat) =>
        '${lat >= 0 ? "北纬" : "南纬"} ${lat.abs().toStringAsFixed(4)}°';
    String formatLng(double lng) =>
        '${lng >= 0 ? "东经" : "西经"} ${lng.abs().toStringAsFixed(4)}°';

    if (wmFields['time'] == true) {
      lines.add('$dateWeekStr  $timeStr');
      if (weatherText.isNotEmpty) {
        lines.add(weatherText);
      }
    }

    if (wmFields['geo'] == true && position != null) {
      lines.add(
        '${formatLat(position!.latitude)}  ${formatLng(position!.longitude)}',
      );
    }

    final List<String> tail = [];
    if (wmFields['altitude'] == true) {
      double displayAlt = apiElevation ?? (position?.altitude ?? 0.0);
      tail.add('海拔 ${displayAlt.toStringAsFixed(1)}m');
    }
    if (wmFields['device'] == true && deviceModelStr.isNotEmpty) {
      tail.add(deviceModelStr);
    }
    if (tail.isNotEmpty) lines.add(tail.join('  '));

    if (wmFields['custom'] == true && customText.value.isNotEmpty) {
      lines.add(customText.value);
    }

    if (lines.isEmpty) return;

    final double minSide = w < h ? w : h;
    final double baseFontSize = (minSide * 0.038).clamp(24.0, 96.0);
    final double headFontSize = baseFontSize * 1.25;
    final double lineGap = baseFontSize * 0.45;
    final double margin = minSide * 0.05;

    final double barWidth = (baseFontSize * 0.16).clamp(4.0, 16.0);
    final double x = margin;
    final double textX = x + barWidth + (baseFontSize * 0.4);
    final double maxTextWidth = w - textX - margin;

    double totalHeight = 0.0;
    List<TextPainter> textPainters = [];

    for (int i = 0; i < lines.length; i++) {
      final isHead = i == 0;
      final fontSize = isHead ? headFontSize : baseFontSize;

      final TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: lines[i],
          style: TextStyle(
            color: isHead ? Colors.white : Colors.white.withOpacity(0.92),
            fontSize: fontSize,
            fontWeight: isHead ? FontWeight.bold : FontWeight.w500,
            fontFamily: 'monospace',
            shadows: const [
              Shadow(
                color: Colors.black54,
                offset: Offset(2, 2),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      );

      textPainter.layout(maxWidth: maxTextWidth);
      textPainters.add(textPainter);

      totalHeight += textPainter.height;
      if (i < lines.length - 1) {
        totalHeight += lineGap;
      }
    }

    final double y = h - margin - totalHeight;

    final Paint barPaint = Paint()
      ..color = const Color(0xFFFFB03A)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(x, y, barWidth, totalHeight), barPaint);

    double currentY = y;
    for (int i = 0; i < textPainters.length; i++) {
      final tp = textPainters[i];
      tp.paint(canvas, Offset(textX, currentY));
      currentY += tp.height + lineGap;
    }
  }

  /// 保存到相册
  Future<void> saveToGallery() async {
    if (isSaving.value) return;

    try {
      bool hasAccess = await Gal.hasAccess();

      if (!hasAccess) {
        final allow = await PermissionDialog.show(
          title: '保存图片或视频到你的相册',
          content: '需要写入相册权限，以便将添加了滤镜和水印的精致照片保存到手机系统中。',
        );
        if (!allow) return;

        hasAccess = await Gal.requestAccess();
        if (!hasAccess) {
          ToastUtil.showError('未获得相册写入权限');
          return;
        }
      }

      isSaving.value = true;
      ToastUtil.show('正在生成高清图片并保存...');

      final Uint8List? bytes = await renderExportBytes();
      if (bytes == null) {
        isSaving.value = false;
        ToastUtil.showError('成片渲染失败，请重试');
        return;
      }

      await Gal.putImageBytes(bytes);
      ToastUtil.showSuccess('照片已成功保存至系统相册');
    } catch (e) {
      ToastUtil.showError('无法保存照片到相册');
    } finally {
      isSaving.value = false;
    }
  }

  /// 分享到第三方应用（适合原始分享图片的方法）
  Future<void> shareImage(BuildContext context) async {
    if (isSaving.value) return;
    isSaving.value = true;

    try {
      ToastUtil.show('正在准备分享文件...');
      final Uint8List? bytes = await renderExportBytes();
      if (bytes == null) {
        isSaving.value = false;
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final String tempPath =
          '${tempDir.path}/share_${DateTime.now().millisecondsSinceEpoch}.png';
      final File tempFile = File(tempPath);
      await tempFile.writeAsBytes(bytes);

      // 1. 获取按钮位置锚点（适配 iPad / iOS 弹窗）
      final box = context.findRenderObject() as RenderBox?;
      final sharePositionOrigin = box != null
          ? box.localToGlobal(Offset.zero) & box.size
          : null;

      // 2. 替换为最新版的 SharePlus.instance.share(ShareParams)
      await SharePlus.instance.share(
        ShareParams(
          text: '匿答水印相机 - 照片分享',
          files: [XFile(tempPath)],
          sharePositionOrigin: sharePositionOrigin,
        ),
      );
    } catch (_) {
      ToastUtil.showError('处理成片失败');
    } finally {
      isSaving.value = false;
    }
  }
}
