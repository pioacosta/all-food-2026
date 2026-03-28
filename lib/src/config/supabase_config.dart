import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  // Fallback para ejecutar la app con --dart-define si hiciera falta.
  static const _urlDefine = String.fromEnvironment('SUPABASE_URL');
  static const _anonKeyDefine = String.fromEnvironment('SUPABASE_ANON_KEY');

  // Prioridad: .env local -> dart-define.
  static String get url =>
      dotenv.env['SUPABASE_URL']?.trim().isNotEmpty == true
          ? dotenv.env['SUPABASE_URL']!.trim()
          : _urlDefine;

  // Prioridad: .env local -> dart-define.
  static String get anonKey =>
      dotenv.env['SUPABASE_ANON_KEY']?.trim().isNotEmpty == true
          ? dotenv.env['SUPABASE_ANON_KEY']!.trim()
          : _anonKeyDefine;

  // Verifica que se pueda inicializar Supabase antes de abrir flujo auth.
  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
