import 'package:all_food/src/features/carta/data/services/carta_service.dart';
import 'package:all_food/src/shared/errors/app_exception.dart';

class CartaFlowException extends AppException {
  const CartaFlowException(super.message);
}

class CartaRepository {
  CartaRepository({CartaService? service})
    : _service = service ?? CartaService();

  final CartaService _service;

  /// Devuelve productos según el tipo (opcional) y búsqueda opcional.
  Future<List<Map<String, dynamic>>> getProductos({
    String? tipo,
    String? nombre,
  }) async {
    if (tipo != null && tipo != 'plato' && tipo != 'bebida') {
      throw const CartaFlowException('Tipo de producto no válido.');
    }

    return _service.getProductos(tipo: tipo, nombre: nombre);
  }

  /// Devuelve un producto por ID. Lanza [CartaFlowException] si no existe.
  Future<Map<String, dynamic>> getProductoById(String id) async {
    final data = await _service.getProductoById(id);
    if (data == null) {
      throw const CartaFlowException('El producto no fue encontrado.');
    }
    return data;
  }

  Future<String?> getUserPerfil() async {
    return _service.getUserPerfil();
  }

  Future<void> editarProducto({
    required String productoId,
    required String tipo,
    required String nombre,
    required String descripcion,
    required int tiempoMin,
    required double precio,
  }) async {
    final perfil = await getUserPerfil();
    _validarPermiso(perfil: perfil, tipo: tipo, accion: 'editar');

    await _service.updateProducto(
      productoId: productoId,
      payload: {
        'nombre': nombre,
        'descripcion': descripcion,
        'tiempo_elaboracion_min': tiempoMin,
        'precio': precio,
      },
    );
  }

  Future<void> eliminarProducto({
    required String productoId,
    required String tipo,
  }) async {
    final perfil = await getUserPerfil();
    _validarPermiso(perfil: perfil, tipo: tipo, accion: 'eliminar');
    await _service.softDeleteProducto(productoId);
  }

  void _validarPermiso({
    required String? perfil,
    required String tipo,
    required String accion,
  }) {
    if (perfil == null) {
      throw const CartaFlowException(
        'No se pudo obtener el perfil del usuario.',
      );
    }

    if (tipo == 'plato' && perfil != 'cocinero') {
      throw CartaFlowException('Solo un cocinero puede $accion platos.');
    }

    if (tipo == 'bebida' && perfil != 'cantinero') {
      throw CartaFlowException('Solo un cantinero puede $accion bebidas.');
    }
  }
}
