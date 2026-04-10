import 'package:all_food/src/features/platos/data/services/platos_service.dart';
import 'package:all_food/src/shared/errors/app_exception.dart';
import 'package:image_picker/image_picker.dart';

// Excepcion de dominio para flujos de alta de platos.
class PlatosFlowException extends AppException {
  const PlatosFlowException(super.message);
}

// Coordina upload de imagenes y persistencia de platos.
class PlatosRepository {
  PlatosRepository({PlatosService? service})
    : _service = service ?? PlatosService();

  final PlatosService _service;

  // Sube una imagen y retorna su URL publica.
  Future<String> uploadDishImage({
    required XFile image,
    required String fileName,
  }) async {
    final bytes = await image.readAsBytes();
    final path = 'platos/$fileName';

    await _service.uploadProductImage(path: path, bytes: bytes);

    return _service.getProductImagePublicUrl(path);
  }

  // Guarda el plato completo en la tabla de productos.
  Future<void> createDish({
    required String nombre,
    required String descripcion,
    required int tiempo,
    required double precio,
    required String foto1,
    required String foto2,
    required String foto3,
  }) {
    return _service.insertProduct({
      'tipo': 'plato',
      'nombre': nombre,
      'descripcion': descripcion,
      'tiempo_elaboracion_min': tiempo,
      'precio': precio,
      'foto_1_url': foto1,
      'foto_2_url': foto2,
      'foto_3_url': foto3,
      'habilitado': true,
    });
  }

  // Garantiza usuario autenticado para generar paths unicos por autor.
  String getCurrentUserIdOrThrow() {
    final userId = _service.currentUserId;
    if (userId == null) {
      throw PlatosFlowException(
        'No hay un usuario autenticado para crear platos.',
      );
    }
    return userId;
  }
}
