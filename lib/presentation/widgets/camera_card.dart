import 'package:flutter/material.dart';

import '../../core/env.dart';
import '../pages/camera_detail_page.dart';
import 'camera_preview.dart';

class CameraCard extends StatelessWidget {
  final String title;
  final String room;
  final VoidCallback? onTap;

  const CameraCard({
    super.key,
    required this.title,
    this.room = 'Bedroom',
    this.onTap,
  });

  void _openDetail(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CameraDetailPage(
          title: title,
          url: Env.demoCameraUrl, // Comentario (ES): URL demo de VDO.Ninja
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => _openDetail(context),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0x11000000)),
            boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 6))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.videocam, color: Colors.black54),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        Text(room, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                      ],
                    ),
                  ),
                  Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                ],
              ),
              const SizedBox(height: 10),
              // 👇 Preview en vivo (WebView embebida)
              CameraPreviewEmbed(url: Env.demoCameraUrl),
            ],
          ),
        ),
      ),
    );
  }
}
