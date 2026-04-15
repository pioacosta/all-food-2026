import 'package:all_food/src/features/carta/data/services/carta_service.dart';
import 'package:all_food/src/shared/errors/app_exception.dart';

class CartaFlowException extends AppException {
  const CartaFlowException(super.message);
}

class CartaRepository {
  CartaRepository({CartaService? service})
      : _service = service ?? CartaService();

  final CartaService _service;

  /// Devuelve productos según el tipo y búsqueda opcional.
  Future<List<Map<String, dynamic>>> getProductos({
    required String tipo,
    String? nombre,
  }) async {
    if (tipo != 'plato' && tipo != 'bebida') {
      throw const CartaFlowException('Tipo de producto no válido.');
    }

    return _service.getProductos(tipo: tipo, nombre: nombre);
  }
}