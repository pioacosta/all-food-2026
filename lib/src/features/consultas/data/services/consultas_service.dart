import 'package:supabase_flutter/supabase_flutter.dart';

class GestionServiciosService {
  GestionServiciosService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<Map<String, dynamic>> getProfileById(String userId) {
    return _client
        .from('perfiles')
        .select('perfil, habilitado')
        .eq('id', userId)
        .single();
  }
  // ───────── CONSULTAS ABIERTAS ─────────

  Future<List<Map<String, dynamic>>> getConsultasAbiertas() async {
    final res = await _client
        .from('consultas_mozo')
        .select('''
        *,
        mesas(numero),
        perfiles(nombres, apellidos),
        mensajes_consulta(mensaje, created_at, emisor_id)
      ''')
        .eq('estado', 'abierta')
        .order('created_at', ascending: false);

    // De todos los mensajes de cada consulta, nos quedamos con el último
    return List<Map<String, dynamic>>.from(res).map((c) {
      final mensajes = (c['mensajes_consulta'] as List?) ?? [];
      mensajes.sort(
        (a, b) =>
            (b['created_at'] as String).compareTo(a['created_at'] as String),
      );
      return {
        ...c,
        'ultimo_mensaje': mensajes.isNotEmpty ? mensajes.first : null,
      };
    }).toList();
  }
}
