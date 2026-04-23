import 'package:supabase_flutter/supabase_flutter.dart';

class ChatService {
  ChatService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String? get currentUserId => _client.auth.currentUser?.id;

  // ─────────────── CONSULTAS ───────────────

  Future<Map<String, dynamic>?> getConsultaActivaPorMesa(String mesaId) async {
    final res =
        await _client
            .from('consultas_mozo')
            .select()
            .eq('mesa_id', mesaId)
            .eq('estado', 'abierta')
            .maybeSingle();

    return res;
  }

  Future<String> crearConsulta({
    required String mesaId,
    required String clienteId,
  }) async {
    final res =
        await _client
            .from('consultas_mozo')
            .insert({'mesa_id': mesaId, 'cliente_id': clienteId})
            .select()
            .single();

    return res['id'];
  }

  Future<String> obtenerOCrearConsulta({
    required String mesaId,
    required String clienteId,
  }) async {
    final existente = await getConsultaActivaPorMesa(mesaId);

    if (existente != null) {
      return existente['id'];
    }

    return await crearConsulta(mesaId: mesaId, clienteId: clienteId);
  }

  Future<void> cerrarConsultaPorMesa(String mesaId) async {
    await _client
        .from('consultas_mozo')
        .update({'estado': 'cerrada'})
        .eq('mesa_id', mesaId)
        .eq('estado', 'abierta');
  }

  // ─────────────── MENSAJES ───────────────

Future<void> enviarMensaje({
  required String consultaId,
  required String mensaje,
}) async {
  final userId = currentUserId;
  if (userId == null) throw Exception('Usuario no autenticado');

  await _client.from('mensajes_consulta').insert({
    'consulta_id': consultaId,
    'emisor_id': userId,
    'mensaje': mensaje,
  });

  // Obtener perfil del emisor y datos de la consulta
  try {
    final perfilData = await _client
        .from('perfiles')
        .select('perfil, nombres')
        .eq('id', userId)
        .single();

    final consultaData = await _client
        .from('consultas_mozo')
        .select('cliente_id')
        .eq('id', consultaId)
        .single();

    final perfil = perfilData['perfil'] as String?;
    final nombres = perfilData['nombres'] as String? ?? 'Usuario';

    if (perfil == 'cliente_registrado' || perfil == 'cliente_anonimo') {
      // Cliente envía → notificar a todos los mozos
      await _client.functions.invoke(
        'notificar-consulta-cliente',
        body: {
          'clienteNombre': nombres,
          'mensaje': mensaje,
        },
      );
    } else if (perfil == 'mozo') {
      // Mozo responde → notificar al cliente
      await _client.functions.invoke(
        'notificar-respuesta-mozo',
        body: {
          'clienteId': consultaData['cliente_id'],
          'mozoNombre': nombres,
          'mensaje': mensaje,
        },
      );
    }
  } catch (_) {
    // Si falla la notificación no bloqueamos el chat
  }
}

  Stream<List<Map<String, dynamic>>> escucharMensajes(String consultaId) {
    // 1. Escuchamos los cambios en la tabla de mensajes
    return _client
        .from('mensajes_consulta')
        .stream(primaryKey: ['id'])
        .eq('consulta_id', consultaId)
        .order('created_at', ascending: false)
        .asyncMap((event) async {
          // 2. Por cada lista de mensajes que llega, enriquecemos con los datos del emisor
          final mensajesEnriquecidos = <Map<String, dynamic>>[];

          for (var m in event) {
            // Buscamos el perfil del emisor y el número de mesa de la consulta
            final dataExtra =
                await _client
                    .from('mensajes_consulta')
                    .select('''
                id,
                perfiles:emisor_id (nombres, perfil),
                consultas_mozo:consulta_id (
                  mesas:mesa_id (numero)
                )
              ''')
                    .eq('id', m['id'])
                    .single();

            mensajesEnriquecidos.add({
              ...m,
              'nombre_emisor': dataExtra['perfiles']?['nombres'] ?? 'Usuario',
              'perfil_emisor':
                  dataExtra['perfiles']?['perfil'], // 'mozo' o 'cliente'
              'numero_mesa':
                  dataExtra['consultas_mozo']?['mesas']?['numero']
                      ?.toString() ??
                  '?',
            });
          }
          return mensajesEnriquecidos;
        });
  }
}
