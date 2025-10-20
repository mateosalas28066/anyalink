// lib/main.dart
// Comentario (ES): App AnyaLink (solo UI) + inicialización de Supabase al arranque.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/env.dart';
import 'presentation/app_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔐 Inicializar Supabase ANTES de usar cualquier provider/instance
  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
  );

  runApp(const ProviderScope(child: AnyaLinkApp()));
}

class AnyaLinkApp extends StatelessWidget {
  const AnyaLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AnyaLink',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF2EC27E),
        brightness: Brightness.light,
      ),
      home: const AppShell(),
    );
  }
}
