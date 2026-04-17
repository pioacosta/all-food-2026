import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

// Capa de acceso a datos para mesas.
// Incluye CRUD de mesas, lista de espera, consulta rápida y chat cliente-mozo.
class MesasService {
  MesasService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<Map<String, dynamic>> getCurrentUserProfile() async {
    final userId = currentUserId;
    if (userId == null) {
      throw const AuthException('No hay un usuario autenticado.');
    }

    return _client
        .from('perfiles')
        .select('perfil, habilitado')
        .eq('id', userId)
        .single();
  }

  // ----- Mesas (ABM) -----
  Future<bool> tableNumberExists(int numeroMesa) async {
    final response = await _client
        .from('mesas')
        .select('id')
        .eq('numero', numeroMesa)
        .limit(1);

    return (response as List).isNotEmpty;
  }

  Future<bool> tableNumberExistsForOther({
    required int numeroMesa,
    required String mesaId,
  }) async {
    final response = await _client
        .from('mesas')
        .select('id')
        .eq('numero', numeroMesa)
        .neq('id', mesaId)
        .limit(1);

    return (response as List).isNotEmpty;
  }

  Future<List<Map<String, dynamic>>> fetchTables() async {
    final response = await _client
        .from('mesas')
        .select('id, numero, cantidad_lugares, tipo, foto_url, qr_codigo')
        .order('numero');

    return List<Map<String, dynamic>>.from(response as List);
  }

  Future<void> uploadTablePhoto({required String path, required File photo}) {
    // Se reutiliza el bucket de avatares para no depender de nuevas migraciones.
    return _client.storage
        .from('avatares')
        .upload(path, photo, fileOptions: const FileOptions(upsert: false));
  }

  String getTablePhotoPublicUrl(String path) {
    return _client.storage.from('avatares').getPublicUrl(path);
  }

  Future<void> insertTable(Map<String, dynamic> payload) {
    return _client.from('mesas').insert(payload);
  }

  Future<Map<String, dynamic>?> getMesaByQrCodigo(String qrCodigo) async {
    final res =
        await _client
            .from('mesas')
            .select('id, numero, qr_codigo, cliente_id, ocupada')
            .eq('qr_codigo', qrCodigo)
            .maybeSingle();

    return res;
  }

  Future<Map<String, dynamic>?> getMesaByClienteId(String clienteId) async {
    final res =
        await _client
            .from('mesas')
            .select('id, numero, tipo, qr_codigo, cliente_id, ocupada')
            .eq('cliente_id', clienteId)
            .maybeSingle();

    return res;
  }

  Future<Map<String, dynamic>> getProfileById(String userId) {
    return _client
        .from('perfiles')
        .select('id, nombres, apellidos, perfil, correo, foto_url')
        .eq('id', userId)
        .single();
  }

  // ----- Lista de espera y asignación -----
  Future<Map<String, dynamic>?> getPendienteSolicitudMesaByCliente(
    String clienteId,
  ) async {
    final res =
        await _client
            .from('solicitudes_mesa')
            .select('id, estado, created_at, mesa_id')
            .eq('cliente_id', clienteId)
            .eq('estado', 'pendiente')
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();

    return res;
  }

  Future<void> createSolicitudMesa({
    required String clienteId,
    required String nombres,
    required String? apellidos,
    required String perfil,
    required String? fotoUrl,
  }) {
    return _client.from('solicitudes_mesa').insert({
      'cliente_id': clienteId,
      'nombres_snapshot': nombres,
      'apellidos_snapshot': apellidos,
      'perfil_snapshot': perfil,
      'foto_url_snapshot': fotoUrl,
      'estado': 'pendiente',
    });
  }

  Future<List<Map<String, dynamic>>> getClientesEnEspera() async {
    final res = await _client
        .from('solicitudes_mesa')
        .select(
          'id, cliente_id, nombres_snapshot, apellidos_snapshot, perfil_snapshot, foto_url_snapshot, created_at',
        )
        .eq('estado', 'pendiente')
        .order('created_at');

    return List<Map<String, dynamic>>.from(res);
  }

  Future<void> marcarSolicitudesAsignadas({
    required String clienteId,
    required String mesaId,
  }) {
    return _client
        .from('solicitudes_mesa')
        .update({'estado': 'asignada', 'mesa_id': mesaId})
        .eq('cliente_id', clienteId)
        .eq('estado', 'pendiente');
  }

  // ----- Consulta rápida (punto 11) -----
  Future<void> crearConsultaMozo({
    required String mesaId,
    required String clienteId,
    required int numeroMesa,
    required String mensaje,
  }) {
    return _client.from('consultas_mozo').insert({
      'mesa_id': mesaId,
      'cliente_id': clienteId,
      'numero_mesa': numeroMesa,
      'mensaje': mensaje,
      'estado': 'pendiente',
    });
  }

  Future<List<Map<String, dynamic>>> getConsultasByClienteMesa({
    required String mesaId,
    required String clienteId,
  }) async {
    final res = await _client
        .from('consultas_mozo')
        .select(
          'id, numero_mesa, mensaje, estado, respuesta_mensaje, created_at, respondido_at',
        )
        .eq('mesa_id', mesaId)
        .eq('cliente_id', clienteId)
        .order('created_at', ascending: false)
        .limit(20);

    return List<Map<String, dynamic>>.from(res);
  }

  // ----- Chat cliente-mozo (punto 11) -----
  Future<List<Map<String, dynamic>>> getMensajesChatMesa({
    required String mesaId,
    String? clienteId,
  }) async {
    final queryBase = _client
        .from('chat_mensajes')
        .select(
          'id, mesa_id, numero_mesa, cliente_id, enviado_por_id, remitente_perfil, mensaje, created_at',
        )
        .eq('mesa_id', mesaId);

    final res =
        clienteId == null
            ? await queryBase.order('created_at')
            : await queryBase.eq('cliente_id', clienteId).order('created_at');

    return List<Map<String, dynamic>>.from(res);
  }

  Future<void> enviarMensajeChat({
    required String mesaId,
    required int numeroMesa,
    required String clienteId,
    required String remitentePerfil,
    required String mensaje,
  }) {
    final emisor = currentUserId;
    if (emisor == null) {
      throw const AuthException('No hay un usuario autenticado.');
    }

    return _client.from('chat_mensajes').insert({
      'mesa_id': mesaId,
      'numero_mesa': numeroMesa,
      'cliente_id': clienteId,
      'enviado_por_id': emisor,
      'remitente_perfil': remitentePerfil,
      'mensaje': mensaje,
    });
  }

  Future<List<Map<String, dynamic>>> getChatsActivosMozo() async {
    final res = await _client
        .from('chat_mensajes')
        .select('mesa_id, numero_mesa, cliente_id, mensaje, created_at')
        .order('created_at', ascending: false)
        .limit(300);

    final rows = List<Map<String, dynamic>>.from(res);
    final uniqueByMesa = <String, Map<String, dynamic>>{};
    // Conserva el último mensaje por mesa para mostrar la bandeja de chats del mozo.
    for (final row in rows) {
      final mesaId = row['mesa_id'] as String?;
      if (mesaId == null || uniqueByMesa.containsKey(mesaId)) continue;
      uniqueByMesa[mesaId] = row;
    }

    return uniqueByMesa.values.toList();
  }

  Future<void> updateTable({
    required String mesaId,
    required Map<String, dynamic> payload,
  }) {
    return _client.from('mesas').update(payload).eq('id', mesaId);
  }

  Future<void> deleteTable(String mesaId) {
    return _client.from('mesas').delete().eq('id', mesaId);
  }

  // ----- Operación de metre -----
  Future<List<Map<String, dynamic>>> getClientesSinMesa() async {
    final res = await _client
        .from('perfiles')
        .select()
        .eq('perfil', 'cliente_registrado')
        .eq('estado_registro', 'aprobado');

    final mesas = await _client.from('mesas').select('cliente_id');

    final clientesConMesa =
        mesas.map((m) => m['cliente_id']).where((id) => id != null).toSet();

    return res.where((c) => !clientesConMesa.contains(c['id'])).toList();
  }

  Future<List<Map<String, dynamic>>> getMesasDisponibles() async {
    final res = await _client
        .from('mesas')
        .select()
        .isFilter('cliente_id', null);

    return List<Map<String, dynamic>>.from(res);
  }

  Future<void> asignarMesa({
    required String clienteId,
    required String mesaId,
  }) async {
    await _client
        .from('mesas')
        .update({'cliente_id': clienteId, 'ocupada': true})
        .eq('id', mesaId);
  }

  Future<void> liberarMesa(String mesaId) async {
    await _client
        .from('mesas')
        .update({'cliente_id': null, 'ocupada': false})
        .eq('id', mesaId);
  }

  Future<Map<String, dynamic>?> buscarMesaPorCliente(String clienteId) async {
    final res =
        await _client
            .from('mesas')
            .select()
            .eq('cliente_id', clienteId)
            .maybeSingle();

    return res;
  }

  Future<List<Map<String, dynamic>>> getMesas() async {
    final res = await _client.from('mesas').select();

    return List<Map<String, dynamic>>.from(res);
  }

  Future<List<Map<String, dynamic>>> getClientesAprobados() async {
    final res = await _client
        .from('perfiles')
        .select()
        .or('perfil.eq.cliente_registrado,perfil.eq.cliente_anonimo')
        .eq('estado_registro', 'aprobado')
        .eq('habilitado', true);

    return List<Map<String, dynamic>>.from(res);
  }

  Future<List<Map<String, dynamic>>> getMesasOcupadas() async {
    final res = await _client
        .from('mesas')
        .select('*, perfiles(nombres, apellidos)')
        .not('cliente_id', 'is', null);

    return List<Map<String, dynamic>>.from(res);
  }
}
