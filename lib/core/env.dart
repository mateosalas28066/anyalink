// lib/core/env.dart
// Comentario (ES): Config de entorno simple.

class Env {
  static const supabaseUrl = 'https://vnalfxtgewdefpoxkuwu.supabase.co';
  static const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZuYWxmeHRnZXdkZWZwb3hrdXd1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg1NjUwNjQsImV4cCI6MjA3NDE0MTA2NH0.3OVHiVAgI9WUJZ4ar3YVOH49N_IAEEwN2f7TBJhXg9M';

  static const lightAlias = 'Lampara';

  // ?? temporal: mejor estabilidad con polling
  static const useRealtime = false;
}

