import 'dart:io';

import 'package:all_food/src/features/clientes/data/services/cliente_service.dart';
import 'package:all_food/src/shared/errors/app_exception.dart';

class ClientesFlowException extends AppException {
  const ClientesFlowException(super.message);
}

class ClientesRepository {
  ClientesRepository({ClientesService? service})
    : _service = service ?? ClientesService();

  final ClientesService _service;

  Future<bool> canCurrentUserCreateClients() async {
    final userId = _service.currentUserId;
    if (userId == null) return false;

    final profile = await _service.getProfileById(userId);

    final rol = (profile['perfil'] as String?) ?? '';
    final habilitado = profile['habilitado'] == true;

    return habilitado && rol == 'metre';
  }

  Future<String> uploadClientPhoto(File foto) async {
    final uid = _service.currentUserId;

    if (uid == null) {
      throw const ClientesFlowException(
        'No hay un usuario autenticado para subir la foto.',
      );
    }

    final millis = DateTime.now().millisecondsSinceEpoch;
    final path = '$uid/client_$millis.jpg';

    await _service.uploadAvatar(path: path, foto: foto);

    return _service.getAvatarPublicUrl(path);
  }

  // ─────────────── ALTA CLIENTE (METRE) ───────────────

  Future<void> createClient({
    required String nombres,
    required String apellidos,
    required String dni,
    required String correo,
    required String password,
    required String fotoUrl,
  }) {
    return _service.createClientViaEdgeFunction({
      'p_nombres': nombres,
      'p_apellidos': apellidos,
      'p_dni': dni,
      'p_correo': correo,
      'p_password': password,
      'p_foto_url': fotoUrl,
    });
  }

  // ─────────────── PENDIENTES ───────────────

  Future<List<Map<String, dynamic>>> getPendingClients() {
    return _service.getPendingClients();
  }

  Future<void> approveClient(String userId) {
    return _service.updateClientStatus(userId, 'aprobado', habilitado: true);
  }

  Future<void> rejectClient(String userId) {
    return _service.updateClientStatus(userId, 'rechazado', habilitado: false);
  }
}
