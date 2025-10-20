// lib/presentation/pages/camera_detail_page.dart
// Comentario (ES): Pantalla de detalle de cámara que carga un stream (VDO.Ninja/RTSP via web) en WebView.

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CameraDetailPage extends StatefulWidget {
  final String title;
  final String url;

  const CameraDetailPage({
    super.key,
    required this.title,
    required this.url,
  });

  @override
  State<CameraDetailPage> createState() => _CameraDetailPageState();
}

class _CameraDetailPageState extends State<CameraDetailPage> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted) // Comentario (ES): VDO.Ninja requiere JS
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            tooltip: 'Reload',
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.reload(),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
