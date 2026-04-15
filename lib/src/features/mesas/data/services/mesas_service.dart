import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

// Capa de acceso a datos para alta y validacion de mesas.
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
        .select('id, numero, cantidad_lugares, tipo, foto_url')
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

  Future<void> updateTable({
    required String mesaId,
    required Map<String, dynamic> payload,
  }) {
    return _client.from('mesas').update(payload).eq('id', mesaId);
  }

  Future<void> deleteTable(String mesaId) {
    return _client.from('mesas').delete().eq('id', mesaId);
  }

  // METRE
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
