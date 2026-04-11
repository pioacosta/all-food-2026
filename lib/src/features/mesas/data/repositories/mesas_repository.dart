import 'dart:io';

import 'package:all_food/src/features/mesas/data/services/mesas_service.dart';
import 'package:all_food/src/shared/errors/app_exception.dart';

class MesasFlowException extends AppException {
  const MesasFlowException(super.message);
}

// Reglas de negocio para crear mesas.
class MesasRepository {
  MesasRepository({MesasService? service})
    : _service = service ?? MesasService();

  final MesasService _service;

  Future<bool> canCurrentUserCreateTables() async {
    final profile = await _service.getCurrentUserProfile();
    final rol = (profile['perfil'] as String?) ?? '';
    final habilitado = profile['habilitado'] == true;

    return habilitado && (rol == 'dueno' || rol == 'supervisor');
  }

  Future<bool> canCurrentUserManageTables() async {
    final profile = await _service.getCurrentUserProfile();
    final rol = (profile['perfil'] as String?) ?? '';
    final habilitado = profile['habilitado'] == true;

    return habilitado &&
        (rol == 'dueno' || rol == 'supervisor' || rol == 'metre');
  }

  Future<bool> tableNumberExists(int numeroMesa) {
    return _service.tableNumberExists(numeroMesa);
  }

  Future<bool> tableNumberExistsForOther({
    required int numeroMesa,
    required String mesaId,
  }) {
    return _service.tableNumberExistsForOther(
      numeroMesa: numeroMesa,
      mesaId: mesaId,
    );
  }

  Future<List<Map<String, dynamic>>> getTables() {
    return _service.fetchTables();
  }

  Future<String> uploadTablePhoto(File photo) async {
    final uid = _service.currentUserId;
    if (uid == null) {
      throw const MesasFlowException('No hay un usuario autenticado.');
    }

    final millis = DateTime.now().millisecondsSinceEpoch;
    final path = '$uid/mesa_$millis.jpg';

    await _service.uploadTablePhoto(path: path, photo: photo);
    return _service.getTablePhotoPublicUrl(path);
  }

  Future<void> createTable({
    required int numeroMesa,
    required int cantidadComensales,
    required String tipoMesa,
    required String fotoUrl,
  }) async {
    final exists = await _service.tableNumberExists(numeroMesa);
    if (exists) {
      throw const MesasFlowException('Ya existe una mesa con ese número.');
    }

    final qrCode = _buildQrCode(numeroMesa);

    await _service.insertTable({
      'numero': numeroMesa,
      'cantidad_lugares': cantidadComensales,
      'tipo': tipoMesa,
      'foto_url': fotoUrl,
      'qr_codigo': qrCode,
      'ocupada': false,
    });
  }

  Future<void> updateTable({
    required String mesaId,
    required int numeroMesa,
    required int cantidadComensales,
    required String tipoMesa,
  }) async {
    final exists = await _service.tableNumberExistsForOther(
      numeroMesa: numeroMesa,
      mesaId: mesaId,
    );

    if (exists) {
      throw const MesasFlowException('Ya existe una mesa con ese número.');
    }

    await _service.updateTable(
      mesaId: mesaId,
      payload: {
        'numero': numeroMesa,
        'cantidad_lugares': cantidadComensales,
        'tipo': tipoMesa,
      },
    );
  }

  Future<void> deleteTable(String mesaId) {
    return _service.deleteTable(mesaId);
  }

  String _buildQrCode(int numeroMesa) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    return 'MESA-$numeroMesa-$ts';
  }
}
