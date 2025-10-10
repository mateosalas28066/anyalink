// lib/presentation/providers/auth_providers.dart
// Comentario (ES): Providers para manejar sesión (JWT) con Supabase Auth y acciones básicas.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Comentario (ES): Stream reactivo de la sesión actual (incluye el valor inicial).
final authSessionProvider = StreamProvider<Session?>((ref) async* {
  final auth = Supabase.instance.client.auth;
  // Emitir sesión actual (si existe) y luego cambios.
  yield auth.currentSession;
  yield* auth.onAuthStateChange.map((event) => event.session);
});

// Comentario (ES): Acciones de autenticación simples (signIn, signUp, signOut).
final authActionsProvider = Provider<_AuthActions>((ref) {
  final auth = Supabase.instance.client.auth;
  return _AuthActions(auth);
});

class _AuthActions {
  final GoTrueClient _auth;
  _AuthActions(this._auth);

  // Comentario (ES): Iniciar sesión con email/contraseña.
  Future<void> signIn({required String email, required String password}) async {
    await _auth.signInWithPassword(email: email, password: password);
  }

  // Comentario (ES): Registrar usuario (dev: sin confirmación si está desactivada en el panel).
  Future<void> signUp({required String email, required String password}) async {
    await _auth.signUp(email: email, password: password);
  }

  // Comentario (ES): Cerrar sesión.
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
