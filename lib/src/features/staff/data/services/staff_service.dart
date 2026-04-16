import 'dart:io';

import 'package:all_food/src/shared/errors/app_exception.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StaffServiceException extends AppException {
  const StaffServiceException(super.message);
}

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

  Future<void> createEmployeeViaEdgeFunction(
    Map<String, dynamic> params,
  ) async {
    try {
      final response = await _client.functions.invoke(
        'crear-empleado-staff',
        body: params,
      );

      if (response.status >= 400) {
        final data = response.data;
        if (data is Map && data['error'] is String) {
          throw StaffServiceException(data['error'] as String);
        }

        throw const StaffServiceException(
          'No se pudo crear el empleado desde el backend.',
        );
      }
    } on FunctionException catch (error) {
      final detail = error.details?.toString().trim() ?? '';
      if (detail.isNotEmpty) {
        throw StaffServiceException(detail);
      }

      throw const StaffServiceException(
        'No se pudo crear el empleado desde el backend.',
      );
    }
  }

}
