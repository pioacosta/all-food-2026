import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:all_food/src/shared/errors/app_exception.dart';
import 'package:all_food/src/features/clientes/data/services/email_service.dart';

class ClientesServiceException extends AppException {
  const ClientesServiceException(super.message);
}

class ClientesService {
  ClientesService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String? get currentUserId => _client.auth.currentUser?.id;

  // ─────────────── PROFILE ───────────────
  Future<Map<String, dynamic>> getProfileById(String userId) {
    return _client
        .from('perfiles')
        .select('perfil, habilitado')
        .eq('id', userId)
        .single();
  }

  // ─────────────── STORAGE ───────────────
  Future<void> uploadAvatar({required String path, required File foto}) {
    return _client.storage
        .from('avatares')
        .upload(path, foto, fileOptions: const FileOptions(upsert: false));
  }

  String getAvatarPublicUrl(String path) {
    return _client.storage.from('avatares').getPublicUrl(path);
  }

  // ─────────────── EDGE FUNCTION ───────────────
  Future<void> createClientViaEdgeFunction(Map<String, dynamic> params) async {
    final response = await _client.functions.invoke(
      'crear-cliente-metre',
      body: params,
    );

    if (response.status >= 400) {
      throw ClientesServiceException(
        response.data['error'] ?? 'Error creando cliente',
      );
    }
  }

  // ─────────────── PENDIENTES ───────────────
  Future<List<Map<String, dynamic>>> getPendingClients() async {
    final res = await _client
        .from('perfiles')
        .select()
        .eq('perfil', 'cliente_registrado')
        .eq('estado_registro', 'pendiente_aprobacion');

    return List<Map<String, dynamic>>.from(res);
  }

  Future<void> updateClientStatus(
    String userId,
    String status, {
    bool? habilitado,
    String? correo,
    String? nombres,           // ✅ eliminado el "required nombre" sin tipo
  }) async {
    final data = <String, dynamic>{'estado_registro': status};

    if (habilitado != null) {
      data['habilitado'] = habilitado;
    }

    await _client.from('perfiles').update(data).eq('id', userId);

    // Enviar email si tenemos los datos
    if (correo != null && nombres != null) {
      await EmailService.enviarEstadoCuenta(
        email: correo,
        nombre: nombres,
        estado: status,
      );
    }
  }
}