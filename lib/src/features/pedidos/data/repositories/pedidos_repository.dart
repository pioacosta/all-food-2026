import 'package:all_food/src/features/carta/data/models/producto_model.dart';
import 'package:all_food/src/features/pedidos/data/services/pedidos_service.dart';
import 'package:all_food/src/shared/errors/app_exception.dart';
import 'package:all_food/src/shared/services/notificaciones_service.dart';

class PedidosFlowException extends AppException {
  const PedidosFlowException(super.message);
}

class PedidosRepository {
  PedidosRepository({PedidosService? service})
    : _service = service ?? PedidosService();

  final PedidosService _service;
  final NotificacionesService _notificacionesService = NotificacionesService();

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

  Future<Map<String, dynamic>> getDetalleCuenta(String mesaId) async {
    final pedido = await _service.getPedidoActivo(mesaId: mesaId);
    if (pedido == null) {
      return {
        'pedidoId': null,
        'estado': 'sin_pedido',
        'emitidoAt': null,
        'lineas': <Map<String, dynamic>>[],
        'subtotal': 0.0,
        'descuentoPorcentaje': 0.0,
        'montoDescuento': 0.0,
        'subtotalConDescuento': 0.0,
        'propinaPorcentaje': 0.0,
        'montoPropina': 0.0,
        'total': 0.0,
      };
    }

    final pedidoId = pedido['id'] as String;
    final items = await _service.getItemsPedido(pedidoId);

    final lineas = <Map<String, dynamic>>[];
    double subtotal = 0;

    for (final item in items) {
      final cantidad = (item['cantidad'] as num?)?.toInt() ?? 0;
      final precioUnitario =
          ((item['precio_unitario'] as num?) ?? 0).toDouble();
      final importe = precioUnitario * cantidad;
      subtotal += importe;

      lineas.add({
        'nombre': item['nombre_snapshot']?.toString() ?? '-',
        'cantidad': cantidad,
        'precioUnitario': precioUnitario,
        'importe': importe,
      });
    }

    final descuentoPorcentaje =
        ((pedido['descuento_juego_porcentaje'] as num?) ?? 0).toDouble();
    final montoDescuento = subtotal * (descuentoPorcentaje / 100);
    final subtotalConDescuento = subtotal - montoDescuento;

    final propinaPorcentaje =
        ((pedido['propina_porcentaje'] as num?) ?? 0).toDouble();
    final montoPropina = subtotalConDescuento * (propinaPorcentaje / 100);

    final totalPersistido = ((pedido['total'] as num?) ?? 0).toDouble();
    final totalCalculado = subtotalConDescuento + montoPropina;
    final total = totalPersistido > 0 ? totalPersistido : totalCalculado;

    return {
      'pedidoId': pedidoId,
      'estado': pedido['estado']?.toString() ?? 'sin_pedido',
      'emitidoAt': pedido['created_at'],
      'lineas': lineas,
      'subtotal': subtotal,
      'descuentoPorcentaje': descuentoPorcentaje,
      'montoDescuento': montoDescuento,
      'subtotalConDescuento': subtotalConDescuento,
      'propinaPorcentaje': propinaPorcentaje,
      'montoPropina': montoPropina,
      'total': total,
    };
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

    await _notificarPerfiles(
      perfiles: const ['mozo'],
      titulo: 'Pedido pendiente de confirmación',
      mensaje: 'Hay un pedido nuevo para revisar.',
      tipo: 'pedido_pendiente_mozo',
      referenciaId: pedidoId,
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

    final pedido = await _service.getPedidoById(pedidoId);
    final clienteId = pedido?['cliente_id'] as String?;
    if (clienteId != null) {
      await _notificacionesService.enviarNotificaciones(
        destinatarios: [clienteId],
        titulo: 'Pedido rechazado por mozo',
        mensaje: 'Debes modificar el pedido. Motivo: $texto',
        tipo: 'pedido_rechazado',
        referenciaId: pedidoId,
      );
    }
  }

  Future<void> confirmarPedido(String pedidoId) async {
    await _service.updatePedido(
      pedidoId: pedidoId,
      payload: {'estado': 'confirmado_mozo', 'observaciones_rechazo': null},
    );

    await _notificarPerfiles(
      perfiles: const ['cocinero', 'cantinero'],
      titulo: 'Nuevo pedido confirmado',
      mensaje: 'Hay productos pendientes para elaborar.',
      tipo: 'pedido_confirmado',
      referenciaId: pedidoId,
    );

    final pedido = await _service.getPedidoById(pedidoId);
    final clienteId = pedido?['cliente_id'] as String?;
    if (clienteId != null) {
      await _notificacionesService.enviarNotificaciones(
        destinatarios: [clienteId],
        titulo: 'Pedido confirmado',
        mensaje: 'Tu pedido fue confirmado y enviado a cocina/bar.',
        tipo: 'pedido_confirmado_cliente',
        referenciaId: pedidoId,
      );
    }
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

    if (todosListos) {
      await _notificarPerfiles(
        perfiles: const ['mozo'],
        titulo: 'Pedido listo para entrega',
        mensaje: 'El pedido está completo y listo para entregar.',
        tipo: 'pedido_listo_entrega',
        referenciaId: pedidoId,
      );

      final pedido = await _service.getPedidoById(pedidoId);
      final clienteId = pedido?['cliente_id'] as String?;
      if (clienteId != null) {
        await _notificacionesService.enviarNotificaciones(
          destinatarios: [clienteId],
          titulo: 'Tu pedido está listo',
          mensaje: 'El mozo lo entregará en breve.',
          tipo: 'pedido_listo_cliente',
          referenciaId: pedidoId,
        );
      }
    }
  }

  Future<void> marcarPedidoEntregado(String pedidoId) {
    return _service
        .updatePedido(
          pedidoId: pedidoId,
          payload: {'estado': 'entregado_por_mozo'},
        )
        .then((_) async {
          final pedido = await _service.getPedidoById(pedidoId);
          final clienteId = pedido?['cliente_id'] as String?;
          if (clienteId != null) {
            await _notificacionesService.enviarNotificaciones(
              destinatarios: [clienteId],
              titulo: 'Pedido entregado',
              mensaje: 'Confirma la recepción de tu pedido.',
              tipo: 'pedido_entregado',
              referenciaId: pedidoId,
            );
          }
        });
  }

  Future<void> confirmarRecepcionCliente(String pedidoId) {
    return _service
        .updatePedido(
          pedidoId: pedidoId,
          payload: {'estado': 'recibido_cliente'},
        )
        .then((_) async {
          await _notificarPerfiles(
            perfiles: const ['mozo'],
            titulo: 'Cliente recibió el pedido',
            mensaje: 'El cliente confirmó recepción del pedido.',
            tipo: 'pedido_recibido_cliente',
            referenciaId: pedidoId,
          );
        });
  }

  Future<void> solicitarCuenta(String pedidoId) {
    return _service
        .updatePedido(
          pedidoId: pedidoId,
          payload: {'estado': 'cuenta_solicitada'},
        )
        .then((_) async {
          await _notificarPerfiles(
            perfiles: const ['mozo'],
            titulo: 'Cliente solicita la cuenta',
            mensaje: 'Un cliente solicitó la cuenta de su mesa.',
            tipo: 'cuenta_solicitada',
            referenciaId: pedidoId,
          );
        });
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

    await _notificarPerfiles(
      perfiles: const ['mozo', 'dueno', 'supervisor'],
      titulo: 'Pago pendiente de confirmación',
      mensaje:
          'El cliente realizó el pago simulado. Falta confirmación del mozo.',
      tipo: 'pago_pendiente_confirmacion',
      referenciaId: pedidoId,
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

    final pedido = await _service.getPedidoById(pedidoId);
    final clienteId = pedido?['cliente_id'] as String?;
    if (clienteId != null) {
      await _notificacionesService.enviarNotificaciones(
        destinatarios: [clienteId],
        titulo: 'Pago confirmado',
        mensaje: 'Tu pago fue confirmado. La mesa quedó liberada.',
        tipo: 'pago_confirmado_cliente',
        referenciaId: pedidoId,
      );
    }

    await _notificarPerfiles(
      perfiles: const ['dueno', 'supervisor'],
      titulo: 'Pago confirmado por mozo',
      mensaje: 'Se confirmó pago y se liberó una mesa.',
      tipo: 'pago_confirmado_staff',
      referenciaId: pedidoId,
    );
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

  Future<List<Map<String, dynamic>>> getSerieSatisfaccionDiaria({
    int maxDias = 7,
  }) async {
    final encuestas = await _service.getEncuestas();
    if (encuestas.isEmpty) return const [];

    final agrupado = <String, Map<String, dynamic>>{};

    for (final e in encuestas) {
      final createdAt = DateTime.tryParse(e['created_at']?.toString() ?? '');
      if (createdAt == null) continue;

      final fechaLocal = createdAt.toLocal();
      final key =
          '${fechaLocal.year.toString().padLeft(4, '0')}-${fechaLocal.month.toString().padLeft(2, '0')}-${fechaLocal.day.toString().padLeft(2, '0')}';

      final item = agrupado.putIfAbsent(
        key,
        () => {
          'fecha': key,
          'sumaComida': 0.0,
          'sumaServicio': 0.0,
          'cantidad': 0,
        },
      );

      item['sumaComida'] =
          ((item['sumaComida'] as num?) ?? 0).toDouble() +
          ((e['puntuacion_comida'] as num?) ?? 0).toDouble();
      item['sumaServicio'] =
          ((item['sumaServicio'] as num?) ?? 0).toDouble() +
          ((e['puntuacion_servicio'] as num?) ?? 0).toDouble();
      item['cantidad'] = ((item['cantidad'] as num?) ?? 0).toInt() + 1;
    }

    final serie =
        agrupado.values.map((item) {
          final cantidad = ((item['cantidad'] as num?) ?? 0).toInt();
          final comida =
              cantidad == 0
                  ? 0.0
                  : ((item['sumaComida'] as num?) ?? 0).toDouble() / cantidad;
          final servicio =
              cantidad == 0
                  ? 0.0
                  : ((item['sumaServicio'] as num?) ?? 0).toDouble() / cantidad;

          return <String, dynamic>{
            'fecha': item['fecha'],
            'comida': comida,
            'servicio': servicio,
          };
        }).toList();

    serie.sort(
      (a, b) => (a['fecha'] as String).compareTo(b['fecha'] as String),
    );
    if (serie.length <= maxDias) return serie;

    return serie.sublist(serie.length - maxDias);
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

  Future<void> _notificarPerfiles({
    required List<String> perfiles,
    required String titulo,
    required String mensaje,
    required String tipo,
    String? referenciaId,
  }) async {
    final destinatarios = await _notificacionesService.getUserIdsByPerfiles(
      perfiles,
    );
    await _notificacionesService.enviarNotificaciones(
      destinatarios: destinatarios,
      titulo: titulo,
      mensaje: mensaje,
      tipo: tipo,
      referenciaId: referenciaId,
    );
  }
}
