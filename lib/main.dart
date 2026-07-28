import 'package:camera/theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';

import 'network/auth_state_manager.dart';
import 'views/splash/splash_view.dart';

void main() async {
  // 确保 Flutter 绑定初始化，这是执行原生相关操作的前提
  WidgetsFlutterBinding.ensureInitialized();

  if (kReleaseMode) {
    // 将 debugPrint 重写为空函数，这样所有的 debugPrint 都会被静音
    debugPrint = (String? message, {int? wrapWidth}) {};
  }

  //测试git

  // 强制竖屏
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 配置沉浸式状态栏 (透明背景，暗色图标)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // 初始化网络权限状态
  await AuthStateManager.instance.checkInitialState();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: '匿名水印相机',
      debugShowCheckedModeBanner: false,
      locale: const Locale('zh', 'CN'),
      fallbackLocale: const Locale('zh', 'CN'),
      supportedLocales: const [
        Locale('zh', 'CN'), // 支持简体中文（中国）
        Locale('en', 'US'), // 支持英语
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.theme.copyWith(
        textSelectionTheme: TextSelectionThemeData(
          // 1. 光标颜色：紫色
          cursorColor: AppTheme.primary,
          // 2. 文本选中的高亮背景色：淡紫色 (20% 透明度)
          selectionColor: AppTheme.primary.withOpacity(0.2),
          // 3. 选中文本左右拉动水滴手柄的颜色：紫色
          selectionHandleColor: AppTheme.primary,
        ),
      ),
      // 首次加载进入水印相机启动页
      home: const SplashView(),
      builder: (context, child) {
        final toastChild = FToastBuilder()(context, child);
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.0)),
          child: toastChild,
        );
      },
    );
  }
}
