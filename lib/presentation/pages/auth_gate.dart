// lib/presentation/pages/auth_gate.dart
// Comentario (ES): Gate mínimo para este ciclo: navega directo a Home (UI).

import 'package:flutter/material.dart';

import 'home_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) => const HomePage();
}
