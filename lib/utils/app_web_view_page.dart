import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// 通用/可复用 WebView 网页展示组件
class AppWebViewPage extends StatefulWidget {
  final String title;
  final String url;

  const AppWebViewPage({super.key, required this.title, required this.url});

  @override
  State<AppWebViewPage> createState() => _AppWebViewPageState();
}

class _AppWebViewPageState extends State<AppWebViewPage> {
  late final WebViewController _controller;
  int _loadingProgress = 0;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initWebViewController();
  }

  void _initWebViewController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFF8FAFC))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (mounted) {
              setState(() {
                _loadingProgress = progress;
              });
            }
          },
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _hasError = false;
              });
            }
          },
          onPageFinished: (String url) {},
          onWebResourceError: (WebResourceError error) {
            if (mounted) {
              setState(() {
                _hasError = true;
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: Color(0xFF0F172A),
          ),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              size: 20,
              color: Color(0xFF475569),
            ),
            tooltip: '刷新网页',
            onPressed: () => _controller.reload(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Web 内容区域
          if (!_hasError)
            WebViewWidget(controller: _controller)
          else
            _buildErrorWidget(),

          // 2. 顶部微细蓝色加载进度条
          if (_loadingProgress < 100 && !_hasError)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                value: _loadingProgress / 100.0,
                backgroundColor: Colors.transparent,
                color: const Color(0xFF2563EB),
                minHeight: 2.5,
              ),
            ),
        ],
      ),
    );
  }

  /// 断网/加载失败极简风提示界面
  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 40,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '网页加载失败',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '请检查网络连接后重新尝试',
              style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _controller.reload(),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('重新加载'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
