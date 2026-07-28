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
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          '编辑照片',
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. 中央预览区域
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Obx(() {
                      if (controller.imagePath.isEmpty) {
                        return Container(
                          color: const Color(0xFF1D1D27),
                          child: const Center(
                            child: Text(
                              '未选择图片',
                              style: TextStyle(color: Colors.white54),
                            ),
                          ),
                        );
                      }

                      return ColorFiltered(
                        colorFilter: ColorFilter.matrix(
                          controller.activeMatrix,
                        ),
                        child: Stack(
                          fit: StackFit.passthrough,
                          children: [
                            Image.file(
                              File(controller.imagePath),
                              fit: BoxFit.contain,
                            ),
                            Positioned(
                              left: 12,
                              bottom: 12,
                              child: _buildRealtimeWatermarkOverlay(),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),

            // 2. 底部控制面板
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFF1D1D27),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 16),

                  // 顶部切换 Tab: 滤镜 | 水印
                  Obx(
                    () => Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildTabItem(title: '滤镜', key: 'filter'),
                        const SizedBox(width: 32),
                        _buildTabItem(title: '水印', key: 'watermark'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Tab 内容区域
                  SizedBox(
                    height: 52,
                    child: Obx(() {
                      if (controller.activeTab.value == 'filter') {
                        return _buildFilterSelector();
                      } else {
                        return _buildWatermarkSelector();
                      }
                    }),
                  ),

                  const SizedBox(height: 24),

                  // 底部三大操作按钮
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => controller.shareImage(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: const Color(0xFF2C2C38),
                              side: BorderSide.none,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              '分 享',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Obx(() {
                            final saving = controller.isSaving.value;
                            return ElevatedButton(
                              onPressed: saving
                                  ? null
                                  : () => controller.saveToGallery(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8B5CF6),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: Text(
                                saving ? '处理中...' : '保存到相册',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRealtimeWatermarkOverlay() {
    return Obx(() {
      final List<String> lines = [];
      final wm = controller.wmFields;

      if (wm['time'] == true) {
        lines.add('${controller.dateWeekStr}  ${controller.timeStr}');
      }
      if (wm['geo'] == true && controller.position != null) {
        lines.add(
          '北纬 ${controller.position!.latitude.toStringAsFixed(4)}°  东经 ${controller.position!.longitude.toStringAsFixed(4)}°',
        );
      }
      final List<String> tail = [];
      if (wm['altitude'] == true && controller.position != null) {
        tail.add('海拔 ${controller.position!.altitude.toStringAsFixed(1)}m');
      }
      if (wm['device'] == true && controller.deviceModelStr.isNotEmpty) {
        tail.add(controller.deviceModelStr);
      }
      if (tail.isNotEmpty) lines.add(tail.join('  '));
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: lines.map((line) {
              return Text(
                line,
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
        ],
      );
    });
  }

  Widget _buildTabItem({required String title, required String key}) {
    final bool isActive = controller.activeTab.value == key;
    return GestureDetector(
      onTap: () => controller.switchTab(key),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white54,
              fontSize: 16,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 2,
            width: 24,
            color: isActive ? const Color(0xFF8B5CF6) : Colors.transparent,
          ),
        ],
      ),
    );
  }

  /// 滤镜选择器（每一项增加 Obx 监听选中高亮）
  Widget _buildFilterSelector() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: controller.filters.length,
      itemBuilder: (context, index) {
        final filter = controller.filters[index];

        return Obx(() {
          final bool isSelected = controller.filterKey.value == filter.key;

          return GestureDetector(
            onTap: () => controller.selectFilter(filter.key),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF8B5CF6)
                    : const Color(0xFF2C2C38),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: Text(
                  filter.name,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontSize: 14,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        });
      },
    );
  }

  /// 水印选择器（每一项增加 Obx 监听开关与取消高亮）
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

          return GestureDetector(
            onTap: () => controller.toggleWatermarkField(key),
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isOn ? const Color(0xFF8B5CF6) : const Color(0xFF2C2C38),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isOn) ...[
                    const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    name,
                    style: TextStyle(
                      color: isOn ? Colors.white : Colors.white70,
                      fontSize: 13,
                      fontWeight: isOn ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }
}
