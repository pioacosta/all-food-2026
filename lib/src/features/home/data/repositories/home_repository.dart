import 'package:all_food/src/features/home/data/services/home_service.dart';

// Orquesta operaciones de Home y oculta detalles del backend.
class HomeRepository {
  HomeRepository({HomeService? service}) : _service = service ?? HomeService();

  final HomeService _service;

  // Retorna el rol del usuario autenticado para controlar permisos en UI.
  Future<String?> getCurrentUserRole() async {
    final userId = _service.currentUserId;
    if (userId == null) return null;

    final profile = await _service.getProfileById(userId);
    return profile['perfil'] as String?;
  }

  // Cierra la sesion actual del usuario.
  Future<void> signOut() {
    return _service.signOut();
  }
}
