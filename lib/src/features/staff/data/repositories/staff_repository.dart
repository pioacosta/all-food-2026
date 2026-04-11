import 'dart:io';

import 'package:all_food/src/features/staff/data/services/staff_service.dart';
import 'package:all_food/src/shared/errors/app_exception.dart';

// Excepcion de dominio para flujos de staff.
class StaffFlowException extends AppException {
  const StaffFlowException(super.message);
}

// Repositorio que concentra permisos y alta de empleados.
class StaffRepository {
  StaffRepository({StaffService? service})
    : _service = service ?? StaffService();

  final StaffService _service;

  // Valida si el usuario actual puede dar de alta empleados.
  Future<bool> canCurrentUserCreateEmployees() async {
    final userId = _service.currentUserId;
    if (userId == null) return false;

    final profile = await _service.getProfileById(userId);
    final rol = (profile['perfil'] as String?) ?? '';
    final habilitado = profile['habilitado'] == true;

    return habilitado && (rol == 'dueno' || rol == 'supervisor');
  }

  // Sube foto personal del empleado y devuelve URL publica.
  Future<String> uploadStaffPhoto(File foto) async {
    final uid = _service.currentUserId;
    if (uid == null) {
      throw const StaffFlowException(
        'No hay un usuario autenticado para subir foto de empleado.',
      );
    }

    final millis = DateTime.now().millisecondsSinceEpoch;
    final path = '$uid/staff_$millis.jpg';

    await _service.uploadAvatar(path: path, foto: foto);
    return _service.getAvatarPublicUrl(path);
  }

  // Invoca Edge Function para crear usuario auth + perfil de staff.
  Future<void> createEmployee({
    required String nombres,
    required String apellidos,
    required String dni,
    required String cuil,
    required String correo,
    required String password,
    required String perfil,
    required String fotoUrl,
  }) {
    return _service.createEmployeeViaEdgeFunction({
      'p_nombres': nombres,
      'p_apellidos': apellidos,
      'p_dni': dni,
      'p_cuil': cuil,
      'p_correo': correo,
      'p_password': password,
      'p_perfil': perfil,
      'p_foto_url': fotoUrl,
    });
  }

  Future<List<Map<String, dynamic>>> PendingClients() {
    return _service.getPendingClients();
  }

  Future<void> approveClient(String userId) {
    return _service.updateClientStatus(userId, 'aprobado', habilitado: true);
    
  }

  Future<void> rejectClient(String userId) {
    return _service.updateClientStatus(userId, 'rechazado', habilitado: false);
  }
}
