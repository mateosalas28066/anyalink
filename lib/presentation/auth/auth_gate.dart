// lib/presentation/auth/auth_gate.dart
// Comentario (ES): Si hay sesión -> AppShell; si no -> SignInPage. Escucha cambios de sesión en vivo.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_shell.dart';
import 'sign_in_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final GoTrueClient _auth = Supabase.instance.client.auth;
  StreamSubscription<AuthState>? _sub;
  Session? _session;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  void _bootstrap() {
    final current = _auth.currentSession;
    setState(() {
      _session = current;
      _loading = false;
    });
    _sub = _auth.onAuthStateChange.listen((event) {
      if (!mounted) return;
      setState(() {
        _session = event.session;
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_session == null) {
      return const SignInPage();
    }
    return const AppShell();
  }
}
