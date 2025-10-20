// lib/presentation/pages/analysis_page.dart
// Comentario (ES): Pantalla vacia con titulo, lista para contenido futuro.

import 'package:flutter/material.dart';

class AnalysisPage extends StatelessWidget {
  const AnalysisPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analysis')),
      body: const Center(
        child: Text('Analysis (WIP)', style: TextStyle(color: Colors.black54)),
      ),
    );
  }
}
