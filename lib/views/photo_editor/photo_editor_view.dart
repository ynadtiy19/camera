import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'photo_editor_controller.dart';

class PhotoEditorView extends GetView<PhotoEditorController> {
  const PhotoEditorView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF13131A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF13131A),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 18,
              ),
              onPressed: () => Get.back(),
            ),
          ),
        ),
        title: const Text(
          '编辑照片',
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. 中央预览区域 (精确贴合图片比例框，解决错位)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Center(
                  child: Obx(() {
                    if (controller.imagePath.isEmpty) {
                      return Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B1B26),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.06),
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            '未选择图片',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ),
                      );
                    }

                    return AspectRatio(
                      aspectRatio: controller.imageAspectRatio.value,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 20,
                              spreadRadius: 2,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: ColorFiltered(
                            colorFilter: ColorFilter.matrix(
                              controller.activeMatrix,
                            ),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                // 底图
                                Image.file(
                                  File(controller.imagePath),
                                  fit: BoxFit.cover,
                                ),

                                // 正中央固定的半透明 Logo 水印
                                Center(
                                  child: IgnorePointer(
                                    child: Text(
                                      '匿答水印相机',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.28),
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 4,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black.withOpacity(
                                              0.35,
                                            ),
                                            offset: const Offset(1, 1),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                // 左下角排版水印层
                                Positioned(
                                  left: 14,
                                  bottom: 14,
                                  right: 14,
                                  child: _buildRealtimeWatermarkOverlay(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),

            // 2. 底部高质感控制面板
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1B1B26),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 18),

                  // 顶部切换分段胶囊 Tab: 滤镜 | 水印
                  _buildTabSegment(),

                  const SizedBox(height: 18),

                  // Tab 内容区域 (水平滑动列表)
                  SizedBox(
                    height: 48,
                    child: Obx(() {
                      if (controller.activeTab.value == 'filter') {
                        return _buildFilterSelector();
                      } else {
                        return _buildWatermarkSelector();
                      }
                    }),
                  ),

                  const SizedBox(height: 22),

                  // 底部精细按键操作行
                  _buildActionButtons(),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 1. 分段胶囊 Tab 控制器 ('滤镜' | '水印')
  Widget _buildTabSegment() {
    return Obx(() {
      final active = controller.activeTab.value;
      return Container(
        height: 42,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: const Color(0xFF222230),
          borderRadius: BorderRadius.circular(21),
          border: Border.all(color: Colors.white.withOpacity(0.06), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTabPill(
              title: '滤镜',
              key: 'filter',
              isActive: active == 'filter',
            ),
            _buildTabPill(
              title: '水印',
              key: 'watermark',
              isActive: active == 'watermark',
            ),
          ],
        ),
      );
    });
  }

  Widget _buildTabPill({
    required String title,
    required String key,
    required bool isActive,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => controller.switchTab(key),
        splashColor: Colors.white.withOpacity(0.12),
        highlightColor: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF323246) : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white54,
                fontSize: 14,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 2. 滤镜选择器 (带触控放大与紫色渐变高亮)
  Widget _buildFilterSelector() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: controller.filters.length,
      itemBuilder: (context, index) {
        final filter = controller.filters[index];

        return Obx(() {
          final bool isSelected = controller.filterKey.value == filter.key;

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: AnimatedScale(
              scale: isSelected ? 1.04 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(24),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => controller.selectFilter(filter.key),
                  splashColor: Colors.white.withOpacity(0.15),
                  highlightColor: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(24),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isSelected ? null : const Color(0xFF252534),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFA78BFA)
                            : Colors.white.withOpacity(0.05),
                        width: 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF8B5CF6).withOpacity(0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [],
                    ),
                    child: Center(
                      child: Text(
                        filter.name,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white60,
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        });
      },
    );
  }

  /// 3. 水印选项卡 (带勾选图标动画与触控反馈)
  Widget _buildWatermarkSelector() {
    final fields = [
      {'key': 'time', 'name': '时间'},
      {'key': 'geo', 'name': '经纬度'},
      {'key': 'altitude', 'name': '海拔'},
      {'key': 'device', 'name': '设备型号'},
      {'key': 'custom', 'name': '自定义文字'},
    ];

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: fields.length,
      itemBuilder: (context, index) {
        final field = fields[index];
        final String key = field['key']!;
        final String name = field['name']!;

        return Obx(() {
          final bool isOn = controller.wmFields[key] == true;

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: AnimatedScale(
              scale: isOn ? 1.03 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(24),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => controller.toggleWatermarkField(key),
                  splashColor: Colors.white.withOpacity(0.15),
                  highlightColor: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(24),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: isOn
                          ? const LinearGradient(
                              colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isOn ? null : const Color(0xFF252534),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isOn
                            ? const Color(0xFFA78BFA)
                            : Colors.white.withOpacity(0.05),
                        width: 1,
                      ),
                      boxShadow: isOn
                          ? [
                              BoxShadow(
                                color: const Color(0xFF8B5CF6).withOpacity(0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: isOn
                              ? const Padding(
                                  padding: EdgeInsets.only(right: 4),
                                  child: Icon(
                                    Icons.check_circle_rounded,
                                    color: Colors.white,
                                    size: 15,
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                        Text(
                          name,
                          style: TextStyle(
                            color: isOn ? Colors.white : Colors.white60,
                            fontSize: 13,
                            fontWeight: isOn
                                ? FontWeight.bold
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        });
      },
    );
  }

  /// 4. 底部两大精细操作按键 ('分 享' 与 '保存到相册')
  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // 分享按钮 (暗灰色高质感玻璃框)
          Expanded(
            child: Material(
              color: const Color(0xFF282838),
              borderRadius: BorderRadius.circular(30),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => controller.shareImage(),
                splashColor: Colors.white.withOpacity(0.12),
                highlightColor: Colors.white.withOpacity(0.05),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.share_outlined, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        '分 享',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // 保存到相册按钮 (紫色光晕渐变)
          Expanded(
            child: Obx(() {
              final saving = controller.isSaving.value;
              return Material(
                borderRadius: BorderRadius.circular(30),
                clipBehavior: Clip.antiAlias,
                color: Colors.transparent,
                child: InkWell(
                  onTap: saving ? null : () => controller.saveToGallery(),
                  splashColor: Colors.white.withOpacity(0.2),
                  highlightColor: Colors.white.withOpacity(0.08),
                  child: Ink(
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6).withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.file_download_outlined,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  '保存到相册',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  /// 5. 实时左下角水印图层
  Widget _buildRealtimeWatermarkOverlay() {
    return Obx(() {
      final List<String> lines = [];
      final wm = controller.wmFields;

      // 时间与实时天气
      if (wm['time'] == true) {
        lines.add('${controller.dateWeekStr}  ${controller.timeStr}');
        if (controller.weatherText.isNotEmpty) {
          lines.add(controller.weatherText);
        }
      }

      // 经纬度
      if (wm['geo'] == true && controller.position != null) {
        lines.add(
          '北纬 ${controller.position!.latitude.toStringAsFixed(4)}°  东经 ${controller.position!.longitude.toStringAsFixed(4)}°',
        );
      }

      // 海拔与设备型号
      final List<String> tail = [];
      if (wm['altitude'] == true) {
        double displayAlt =
            controller.apiElevation ?? (controller.position?.altitude ?? 0.0);
        tail.add('海拔 ${displayAlt.toStringAsFixed(1)}m');
      }
      if (wm['device'] == true && controller.deviceModelStr.isNotEmpty) {
        tail.add(controller.deviceModelStr);
      }
      if (tail.isNotEmpty) lines.add(tail.join('  '));

      // 自定义文字
      if (wm['custom'] == true && controller.customText.value.isNotEmpty) {
        lines.add(controller.customText.value);
      }

      if (lines.isEmpty) return const SizedBox.shrink();

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 3,
            height: lines.length * 15.0,
            color: const Color(0xFFFFB03A),
            margin: const EdgeInsets.only(right: 6, top: 2),
          ),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: lines.map((line) {
                return Text(
                  line,
                  softWrap: true,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    shadows: [Shadow(color: Colors.black, blurRadius: 3)],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      );
    });
  }
}
