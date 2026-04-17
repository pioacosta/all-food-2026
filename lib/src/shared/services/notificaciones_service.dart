import 'package:supabase_flutter/supabase_flutter.dart';

class NotificacionesService {
  NotificacionesService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<List<String>> getUserIdsByPerfiles(List<String> perfiles) async {
    if (perfiles.isEmpty) return const [];

    final rows = await _client
        .from('perfiles')
        .select('id')
        .inFilter('perfil', perfiles)
        .eq('habilitado', true);

    return List<Map<String, dynamic>>.from(
      rows,
    ).map((e) => e['id'] as String?).whereType<String>().toList();
  }

  Future<void> enviarNotificaciones({
    required List<String> destinatarios,
    required String titulo,
    required String mensaje,
    required String tipo,
    String? referenciaId,
    Map<String, dynamic>? payload,
  }) async {
    final emisorId = currentUserId;
    if (emisorId == null || destinatarios.isEmpty) return;

    final uniques = destinatarios.toSet().toList();
    if (uniques.isEmpty) return;

    final rows =
        uniques
            .map(
              (destinatarioId) => <String, dynamic>{
                'emisor_id': emisorId,
                'destinatario_id': destinatarioId,
                'titulo': titulo,
                'mensaje': mensaje,
                'tipo': tipo,
                'referencia_id': referenciaId,
                'payload': payload,
              },
            )
            .toList();

    await _client.from('notificaciones').insert(rows);
  }
}
