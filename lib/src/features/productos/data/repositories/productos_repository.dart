import 'package:all_food/src/features/productos/data/services/productos_service.dart';
import 'package:all_food/src/shared/errors/app_exception.dart';
import 'package:image_picker/image_picker.dart';

/// Excepción de dominio para flujos de productos.
class ProductosFlowException extends AppException {
  const ProductosFlowException(super.message);
}

/// Coordina upload de imágenes y persistencia de productos.
class ProductosRepository {
  ProductosRepository({ProductosService? service})
      : _service = service ?? ProductosService();

  final ProductosService _service;

  /// Subir imagen y devolver URL pública
  Future<String> uploadProductImage({
    required XFile image,
    required String fileName,
  }) async {
    final bytes = await image.readAsBytes();
    final path = 'productos/$fileName';
    await _service.uploadProductImage(path: path, bytes: bytes);
    return _service.getProductImagePublicUrl(path);
  }

  /// Crear producto (plato o bebida)
  Future<void> createProduct({
    required String tipo,
    required String nombre,
    required String descripcion,
    required int tiempo,
    required double precio,
    required String foto1,
    required String foto2,
    required String foto3,
  }) async {
    await validateRoleForProduct(tipo);

    await _service.insertProduct({
      'tipo': tipo,
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

  /// Validar rol según tipo de producto
  Future<void> validateRoleForProduct(String tipo) async {
    final perfil = await _service.getUserPerfil();

    if (perfil == null) {
      throw const ProductosFlowException(
        'No se pudo obtener el perfil del usuario.',
      );
    }

    if (tipo == 'plato' && perfil != 'cocinero') {
      throw const ProductosFlowException(
        'Solo un cocinero puede crear platos.',
      );
    }

    if (tipo == 'bebida' && perfil != 'cantinero') {
      throw const ProductosFlowException(
        'Solo un cantinero puede crear bebidas.',
      );
    }
  }

  /// Obtener perfil del usuario actual
  Future<String?> getUserPerfil() async {
    return _service.getUserPerfil();
  }

  /// Obtener userId o lanzar excepción
  String getCurrentUserIdOrThrow() {
    final userId = _service.currentUserId;

    if (userId == null) {
      throw const ProductosFlowException(
        'No hay un usuario autenticado.',
      );
    }

    return userId;
  }
}