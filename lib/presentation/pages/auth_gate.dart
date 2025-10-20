// lib/presentation/pages/auth_gate.dart
// Comentario (ES): Gate mínimo para este ciclo: navega directo al shell principal.

import 'package:flutter/material.dart';

import '../app_shell.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) => const AppShell();
}
