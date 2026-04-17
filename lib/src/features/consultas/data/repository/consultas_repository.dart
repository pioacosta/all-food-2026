import 'package:all_food/src/features/consultas/data/services/consultas_service.dart';

class GestionServiciosRepository {
  GestionServiciosRepository({GestionServiciosService? service})
    : _service = service ?? GestionServiciosService();

  final GestionServiciosService _service;

  Future<bool> canCurrentUserListMessages() async {
    final userId = _service.currentUserId;
    if (userId == null) return false;

    final profile = await _service.getProfileById(userId);
    final rol = (profile['perfil'] as String?) ?? '';
    final habilitado = profile['habilitado'] == true;

    return habilitado && rol == 'mozo';
  }

  Future<List<Map<String, dynamic>>> getConsultasAbiertas() {
    return _service.getConsultasAbiertas();
  }
}
