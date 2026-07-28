import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 水印相机 / 自定义相机 - 品牌高质感主题定义
class AppTheme {
  AppTheme._();

  // ==========================================
  // 核心色彩定义 (Color Palette)
  // ==========================================

  /// 主色调 - 紫罗兰浪漫紫
  static const Color primary = Color(0xFF6B46FE);
  static const Color primaryLight = Color(0xFF9853FF);
  static const Color primaryDark = Color(0xFF5231D9);

  /// 辅助色 / 功能色
  static const Color accentBlue = Color(0xFF5373FE); // 修图图标蓝
  static const Color success = Color(0xFF20C997);
  static const Color warning = Color(0xFFFFB020);
  static const Color error = Color(0xFFFF4D4F);

  /// 背景与表面
  static const Color background = Color(0xFFF6F7FB); // 主界面冷灰微光背景
  static const Color surface = Colors.white; // 卡片/容器纯白
  static const Color cardBorder = Color(0xFFF0F1F6); // 极浅微光边框

  /// 文字颜色阶梯
  static const Color textPrimary = Color(0xFF1D1E2C); // 标题深灰黑
  static const Color textSecondary = Color(0xFF6E7191); // 正文/副标题灰
  static const Color textMuted = Color(0xFFA0A3BD); // 提示/次要文字
  static const Color textWhite = Colors.white;

  // ==========================================
  // 渐变与阴影样式 (Gradients & Shadows)
  // ==========================================

  /// 主紫渐变 (顶部“下午好”卡片背景)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6643FE), Color(0xFF9B52FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// 按钮微光渐变
  static const LinearGradient buttonGradient = LinearGradient(
    colors: [Color(0xFF724EFF), Color(0xFFA25BFF)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  /// 基础卡片微柔阴影
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: const Color(0xFF6B46FE).withOpacity(0.06),
      blurRadius: 20,
      offset: const Offset(0, 8),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.02),
      blurRadius: 10,
      offset: const Offset(0, 2),
      spreadRadius: 0,
    ),
  ];

  // ==========================================
  // ThemeData 主题导出
  // ==========================================

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: primaryLight,
        surface: surface,
        background: background,
        error: error,
        brightness: Brightness.light,
      ),

      /// 全局背景色
      scaffoldBackgroundColor: background,

      /// 顶部 Status Bar 与 导航栏样式
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
        iconTheme: IconThemeData(color: textPrimary, size: 24),
      ),

      /// 卡片全局样式
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: cardBorder, width: 1),
        ),
      ),

      /// 按钮主题配置
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: textWhite,
          elevation: 0,
          shadowColor: primary.withOpacity(0.3),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100), // 全圆角胶囊状
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      /// 描边按钮 (如卡片内半透明“开始拍摄”)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textWhite,
          side: BorderSide(color: Colors.white.withOpacity(0.4), width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      /// 文字主题定义
      textTheme: const TextTheme(
        // 大标题 (例: 下午好)
        displaySmall: TextStyle(
          color: textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        // 中标题 (例: 相册修图、小贴士)
        titleLarge: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          height: 1.3,
        ),
        // 小标题/常规加粗
        titleMedium: TextStyle(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        // 标准正文
        bodyLarge: TextStyle(
          color: textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.normal,
          height: 1.5,
        ),
        // 次要正文 (例: 从相册选一张照片...)
        bodyMedium: TextStyle(
          color: textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.normal,
          height: 1.4,
        ),
        // 提示性小字
        bodySmall: TextStyle(
          color: textMuted,
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
      ),

      /// 底部导航栏主题
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textMuted,
        elevation: 10,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
      ),

      /// 触摸反馈波纹颜色
      splashColor: primary.withOpacity(0.08),
      highlightColor: primary.withOpacity(0.04),
    );
  }
}
