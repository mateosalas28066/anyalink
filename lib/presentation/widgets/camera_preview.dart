// lib/presentation/widgets/camera_preview.dart
// Comentario (ES): Preview embebido con WebView (VDO.Ninja) en miniatura, silenciado y autoplay.

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CameraPreviewEmbed extends StatefulWidget {
  final String url; // URL base de VDO.Ninja (con ?view=...)
  const CameraPreviewEmbed({super.key, required this.url});

  @override
  State<CameraPreviewEmbed> createState() => _CameraPreviewEmbedState();
}

class _CameraPreviewEmbedState extends State<CameraPreviewEmbed> {
  static WebViewController? _cachedController; // Comentario (ES): Reusar controlador para no recargar
  bool _isLoading = true;

  String get _previewUrl {
    // Comentario (ES): Parámetros para autoplay silencioso, salida limpia y carga ligera
    final sep = widget.url.contains('?') ? '&' : '?';
    return '${widget.url}'
        '${sep}autostart=1'
        '&muted=1'
        '&cleanoutput'
        '&transparent=1'
        '&stats=0'
        '&nocursor=1'
        '&label=preview';
  }

  @override
  void initState() {
    super.initState();
    if (_cachedController == null) {
      final c = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.black)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (_) => setState(() => _isLoading = true),
            onPageFinished: (_) => setState(() => _isLoading = false),
            onWebResourceError: (_) => setState(() => _isLoading = false),
          ),
        )
        ..loadRequest(Uri.parse(_previewUrl));
      _cachedController = c;
    } else {
      // Si ya existe, recarga a la URL final por si cambió
      _cachedController!.loadRequest(Uri.parse(_previewUrl));
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _cachedController!;
    return Stack(
      children: [
        // Comentario (ES): Relación 4:3 para la miniatura
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: WebViewWidget(controller: controller),
          ),
        ),
        if (_isLoading)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFEAECEF),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: const Text('Loading preview...', style: TextStyle(color: Colors.black54)),
            ),
          ),
      ],
    );
  }
}
