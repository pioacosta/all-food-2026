import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

// Capa de acceso a datos para permisos y alta de empleados.
class StaffService {
  StaffService({SupabaseClient? client})
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

  Future<void> uploadAvatar({required String path, required File foto}) {
    return _client.storage
        .from('avatares')
        .upload(path, foto, fileOptions: const FileOptions(upsert: false));
  }

  String getAvatarPublicUrl(String path) {
    return _client.storage.from('avatares').getPublicUrl(path);
  }

  Future<void> createEmployeeViaRpc(Map<String, dynamic> params) {
    return _client.rpc('crear_empleado_staff', params: params);
  }
}
