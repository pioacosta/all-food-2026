import 'package:supabase_flutter/supabase_flutter.dart';

// Servicio transversal para notificaciones internas en tiempo real.
// Inserta eventos en la tabla `notificaciones` y los clientes escuchan por Realtime.
class NotificacionesService {
  NotificacionesService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String? get currentUserId => _client.auth.currentUser?.id;

  // Resuelve destinatarios por perfil de negocio (mozo, metre, dueno, etc.).
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
    // Si no hay sesión o no hay destinatarios, no se emite notificación.
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
