import 'package:all_food/src/features/carta/data/models/producto_model.dart';
import 'package:all_food/src/features/pedidos/data/services/pedidos_service.dart';
import 'package:all_food/src/shared/errors/app_exception.dart';

class PedidosFlowException extends AppException {
  const PedidosFlowException(super.message);
}

class PedidosRepository {
  PedidosRepository({PedidosService? service})
    : _service = service ?? PedidosService();

  final PedidosService _service;

  static const List<int> propinasPermitidas = [0, 5, 10, 15, 20];

  Future<Map<String, dynamic>?> getPedidoActivoMesa(String mesaId) {
    return _service.getPedidoActivo(mesaId: mesaId);
  }

  Future<Map<String, dynamic>> asegurarPedidoEditable(String mesaId) async {
    final uid = _service.currentUserId;
    if (uid == null) {
      throw const PedidosFlowException('No hay un usuario autenticado.');
    }

    final pedidoActual = await _service.getPedidoActivo(mesaId: mesaId);
    if (pedidoActual == null) {
      return _service.createPedido(mesaId: mesaId, clienteId: uid);
    }

    final estado = pedidoActual['estado'] as String? ?? 'borrador';
    if (estado != 'borrador' && estado != 'rechazado_mozo') {
      throw const PedidosFlowException(
        'Este pedido no se puede modificar en el estado actual.',
      );
    }

    return pedidoActual;
  }

  Future<void> agregarProducto({
    required String mesaId,
    required ProductoModel producto,
  }) async {
    final pedido = await asegurarPedidoEditable(mesaId);
    final pedidoId = pedido['id'] as String;

    final existente = await _service.getPedidoItem(
      pedidoId: pedidoId,
      productoId: producto.id,
    );

    if (existente == null) {
      await _service.insertPedidoItem({
        'pedido_id': pedidoId,
        'producto_id': producto.id,
        'tipo_producto': producto.tipo,
        'nombre_snapshot': producto.nombre,
        'cantidad': 1,
        'precio_unitario': producto.precio,
        'tiempo_elaboracion_min': producto.tiempoMin,
        'estado': 'pendiente',
      });
    } else {
      await _service.updatePedidoItem(
        itemId: existente['id'] as String,
        payload: {'cantidad': (existente['cantidad'] as int) + 1},
      );
    }

    await _recalcularTotalesPedido(pedidoId);
  }

  Future<Map<String, dynamic>> getDetallePedido(String mesaId) async {
    final pedido = await _service.getPedidoActivo(mesaId: mesaId);
    if (pedido == null) {
      return {
        'pedido': null,
        'items': <Map<String, dynamic>>[],
        'tiempoTotalMin': 0,
      };
    }

    final items = await _service.getItemsPedido(pedido['id'] as String);
    final tiempo = _calcularTiempoTotal(items);

    return {'pedido': pedido, 'items': items, 'tiempoTotalMin': tiempo};
  }

  Future<void> cambiarCantidadItem({
    required String pedidoId,
    required String itemId,
    required int nuevaCantidad,
  }) async {
    if (nuevaCantidad <= 0) {
      await _service.deletePedidoItem(itemId);
    } else {
      await _service.updatePedidoItem(
        itemId: itemId,
        payload: {'cantidad': nuevaCantidad},
      );
    }
    await _recalcularTotalesPedido(pedidoId);
  }

  Future<void> enviarPedidoAMozo(String pedidoId) async {
    final items = await _service.getItemsPedido(pedidoId);
    if (items.isEmpty) {
      throw const PedidosFlowException(
        'Debes agregar al menos un producto al pedido.',
      );
    }

    await _service.updatePedido(
      pedidoId: pedidoId,
      payload: {'estado': 'pendiente_mozo', 'observaciones_rechazo': null},
    );
  }

  Future<List<Map<String, dynamic>>> getPedidosPendientesMozo() {
    return _service.getPedidosByEstado(estados: ['pendiente_mozo']);
  }

  Future<List<Map<String, dynamic>>> getPedidosListosEntrega() {
    return _service.getPedidosByEstado(estados: ['listo_para_entrega']);
  }

  Future<List<Map<String, dynamic>>> getPedidosPagoPendiente() {
    return _service.getPedidosByEstado(
      estados: ['pago_pendiente_confirmacion'],
    );
  }

  Future<void> rechazarPedido({
    required String pedidoId,
    required String motivo,
  }) async {
    final texto = motivo.trim();
    if (texto.length < 3) {
      throw const PedidosFlowException('Debes indicar un motivo de rechazo.');
    }

    await _service.updatePedido(
      pedidoId: pedidoId,
      payload: {'estado': 'rechazado_mozo', 'observaciones_rechazo': texto},
    );
  }

  Future<void> confirmarPedido(String pedidoId) async {
    await _service.updatePedido(
      pedidoId: pedidoId,
      payload: {'estado': 'confirmado_mozo', 'observaciones_rechazo': null},
    );
  }

  Future<List<Map<String, dynamic>>> getItemsPendientesCocina() {
    return _service.getItemsSector(tipoProducto: 'plato');
  }

  Future<List<Map<String, dynamic>>> getItemsPendientesBar() {
    return _service.getItemsSector(tipoProducto: 'bebida');
  }

  Future<void> marcarItemListo({
    required String pedidoId,
    required String itemId,
  }) async {
    await _service.updatePedidoItem(
      itemId: itemId,
      payload: {'estado': 'listo'},
    );

    final items = await _service.getItemsPedido(pedidoId);
    final todosListos =
        items.isNotEmpty && items.every((e) => e['estado'] == 'listo');

    await _service.updatePedido(
      pedidoId: pedidoId,
      payload: {
        'estado': todosListos ? 'listo_para_entrega' : 'en_preparacion',
      },
    );
  }

  Future<void> marcarPedidoEntregado(String pedidoId) {
    return _service.updatePedido(
      pedidoId: pedidoId,
      payload: {'estado': 'entregado_por_mozo'},
    );
  }

  Future<void> confirmarRecepcionCliente(String pedidoId) {
    return _service.updatePedido(
      pedidoId: pedidoId,
      payload: {'estado': 'recibido_cliente'},
    );
  }

  Future<void> solicitarCuenta(String pedidoId) {
    return _service.updatePedido(
      pedidoId: pedidoId,
      payload: {'estado': 'cuenta_solicitada'},
    );
  }

  Future<Map<String, dynamic>> prepararPagoConPropina({
    required String pedidoId,
    required int propinaPorcentaje,
  }) async {
    if (!propinasPermitidas.contains(propinaPorcentaje)) {
      throw const PedidosFlowException('La propina seleccionada no es válida.');
    }

    final pedido = await _service
        .getPedidosByEstado(
          estados: [
            'cuenta_solicitada',
            'recibido_cliente',
            'pago_pendiente_confirmacion',
          ],
        )
        .then((list) => list.firstWhere((e) => e['id'] == pedidoId));

    final subtotal = ((pedido['subtotal'] as num?) ?? 0).toDouble();
    final descuento =
        ((pedido['descuento_juego_porcentaje'] as num?) ?? 0).toDouble();
    final baseConDescuento = subtotal * (1 - descuento / 100);
    final totalFinal = baseConDescuento * (1 + propinaPorcentaje / 100);

    await _service.updatePedido(
      pedidoId: pedidoId,
      payload: {
        'propina_porcentaje': propinaPorcentaje,
        'total': totalFinal,
        'estado': 'pago_pendiente_confirmacion',
      },
    );

    return {
      'subtotal': subtotal,
      'descuentoPorcentaje': descuento,
      'propinaPorcentaje': propinaPorcentaje,
      'total': totalFinal,
    };
  }

  Future<void> confirmarPagoMozo({
    required String pedidoId,
    required String mesaId,
  }) async {
    await _service.updatePedido(
      pedidoId: pedidoId,
      payload: {'estado': 'cerrado'},
    );
    await _service.liberarMesa(mesaId);
  }

  Future<void> guardarEncuesta({
    required String pedidoId,
    required int puntuacionComida,
    required int puntuacionServicio,
    required bool recomendaria,
    required String comentario,
  }) async {
    final uid = _service.currentUserId;
    if (uid == null) {
      throw const PedidosFlowException('No hay un usuario autenticado.');
    }

    await _service.insertEncuesta({
      'pedido_id': pedidoId,
      'cliente_id': uid,
      'puntuacion_comida': puntuacionComida,
      'puntuacion_servicio': puntuacionServicio,
      'recomendaria': recomendaria,
      'comentario': comentario.trim().isEmpty ? null : comentario.trim(),
    });

    await _service.updatePedido(
      pedidoId: pedidoId,
      payload: {'encuesta_completada': true},
    );
  }

  Future<Map<String, dynamic>> getResumenEncuestas() async {
    final encuestas = await _service.getEncuestas();
    if (encuestas.isEmpty) {
      return {
        'cantidad': 0,
        'promedioComida': 0.0,
        'promedioServicio': 0.0,
        'porcentajeRecomendacion': 0.0,
      };
    }

    double sumaComida = 0;
    double sumaServicio = 0;
    int recomienda = 0;

    for (final e in encuestas) {
      sumaComida += ((e['puntuacion_comida'] as num?) ?? 0).toDouble();
      sumaServicio += ((e['puntuacion_servicio'] as num?) ?? 0).toDouble();
      if (e['recomendaria'] == true) recomienda++;
    }

    return {
      'cantidad': encuestas.length,
      'promedioComida': sumaComida / encuestas.length,
      'promedioServicio': sumaServicio / encuestas.length,
      'porcentajeRecomendacion': (recomienda * 100) / encuestas.length,
    };
  }

  int _calcularTiempoTotal(List<Map<String, dynamic>> items) {
    var total = 0;
    for (final item in items) {
      final tiempo = (item['tiempo_elaboracion_min'] as num?)?.toInt() ?? 0;
      final cantidad = (item['cantidad'] as num?)?.toInt() ?? 0;
      total += tiempo * cantidad;
    }
    return total;
  }

  Future<void> _recalcularTotalesPedido(String pedidoId) async {
    final items = await _service.getItemsPedido(pedidoId);
    double subtotal = 0;

    for (final item in items) {
      final precio = ((item['precio_unitario'] as num?) ?? 0).toDouble();
      final cantidad = (item['cantidad'] as num?)?.toInt() ?? 0;
      subtotal += precio * cantidad;
    }

    await _service.updatePedido(
      pedidoId: pedidoId,
      payload: {'subtotal': subtotal, 'total': subtotal},
    );
  }
}
