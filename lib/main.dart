// lib/main.dart
// Comentario (ES): App con tema claro y brand AnyaLink.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/env.dart';
import 'presentation/pages/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Comentario (ES): Inicializa Supabase con tus credenciales.
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
    // Comentario (ES): Paleta clara tipo "tarjetas blancas" y acento verde.
    const seed = Color(0xFF2EC27E); // verde acento (switch, resaltes)
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
    );

    return MaterialApp(
      title: 'AnyaLink',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFFF3F4F6), // gris muy claro
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black87,
        ),
        textTheme: const TextTheme(
          headlineSmall: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      home: const HomePage(),
    );
  }
}
