import 'dart:async';

import 'package:all_food/src/features/carta/presentation/pages/carta_cliente.dart';
import 'package:all_food/src/features/pedidos/data/repositories/pedidos_repository.dart';
import 'package:all_food/src/features/pedidos/presentation/pages/encuesta_cliente_page.dart';
import 'package:all_food/src/features/pedidos/presentation/pages/resultados_encuestas_page.dart';
import 'package:all_food/src/features/pedidos/presentation/widgets/cierre_countdown_dialog.dart';
import 'package:all_food/src/shared/errors/app_error_mapper.dart';
import 'package:all_food/src/shared/utils/buenos_aires_time.dart';
import 'package:all_food/src/shared/widgets/logo_spinner.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:all_food/src/features/pedidos/presentation/pages/propina_qr_scanner_page.dart';

class ClientePedidoPage extends StatefulWidget {
  const ClientePedidoPage({
    required this.mesaId,
    required this.numeroMesa,
    super.key,
  });

  final String mesaId;
  final int numeroMesa;

  @override
  State<ClientePedidoPage> createState() => _ClientePedidoPageState();
}

class _ClientePedidoPageState extends State<ClientePedidoPage> {
  final _repo = PedidosRepository();
  RealtimeChannel? _pedidoChannel;

  bool _cargando = true;
  bool _procesando = false;
  bool _redireccionando = false;
  bool _sincronizandoRealtime = false;
  Map<String, dynamic>? _pedido;
  List<Map<String, dynamic>> _items = [];
  int _tiempoTotal = 0;

  @override
  void initState() {
    super.initState();
    // Al entrar, sincroniza el estado actual del pedido de la mesa.
    _cargar();
    _iniciarEscuchaPedidoRealtime();
  }

  @override
  void dispose() {
    _detenerEscuchaPedidoRealtime();
    super.dispose();
  }

  void _iniciarEscuchaPedidoRealtime() {
    final client = Supabase.instance.client;

    _pedidoChannel?.unsubscribe();
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    _pedidoChannel =
        client
            .channel('pedido_cliente_${widget.mesaId}_$timestamp')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'pedidos',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'mesa_id',
                value: widget.mesaId,
              ),
              callback: (payload) {
                debugPrint(
                  '[Realtime] estado=$mounted redireccionando=$_redireccionando',
                );
                if (!mounted || _redireccionando) return;
                _cargarSilencioso();
              },
            )
            .subscribe();
  }

  Future<void> _detenerEscuchaPedidoRealtime() async {
    final channel = _pedidoChannel;
    _pedidoChannel = null;
    if (channel != null) {
      await channel.unsubscribe();
    }
  }

  Future<void> _cargarSilencioso() async {
    if (_sincronizandoRealtime) return;
    _sincronizandoRealtime = true;
    try {
      final detalle = await _repo.getDetallePedido(
        widget.mesaId,
        incluirCerrado: true,
      );
      if (!mounted || _redireccionando) return;

      final estadoNuevo =
          (detalle['pedido'] as Map<String, dynamic>?)?['estado'] as String?;

      if (estadoNuevo == 'cerrado') {
        _pedido = detalle['pedido'] as Map<String, dynamic>?;
        await _verificarCierreYRedirigir();
        return;
      }

      setState(() {
        _pedido = detalle['pedido'] as Map<String, dynamic>?;
        _items = List<Map<String, dynamic>>.from(detalle['items'] as List);
        _tiempoTotal = (detalle['tiempoTotalMin'] as num?)?.toInt() ?? 0;
      });
    } catch (e) {
      debugPrint('[Realtime] Error en _cargarSilencioso: $e');
    } finally {
      _sincronizandoRealtime = false;
    }
  }

  Future<void> _verificarCierreYRedirigir() async {
    final estado = (_pedido?['estado'] as String?) ?? 'sin_pedido';
    if (estado != 'cerrado' || _redireccionando || !mounted) return;

    _redireccionando = true;
    await _detenerEscuchaPedidoRealtime();

    // Mostrar modal con cuenta regresiva antes de redirigir
    await _mostrarModalCierreYRedirigir();
  }

  Future<void> _mostrarModalCierreYRedirigir() async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => CierreCountdownDialog(
            onComplete: () {
              Navigator.of(context).pop(); // cierra el dialog
            },
          ),
    );

    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
  }

  // Carga pedido + ítems + tiempo estimado acumulado.
  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      // incluirCerrado: false (default) — si la page abre y hay un cerrado viejo, lo ignora
      final detalle = await _repo.getDetallePedido(widget.mesaId);
      if (!mounted) return;

      final estadoNuevo =
          (detalle['pedido'] as Map<String, dynamic>?)?['estado'] as String?;

      // Con incluirCerrado: false esto nunca será 'cerrado', pero por seguridad:
      if (estadoNuevo == 'cerrado') {
        _pedido = detalle['pedido'] as Map<String, dynamic>?;
        await _verificarCierreYRedirigir();
        return;
      }

      setState(() {
        _pedido = detalle['pedido'] as Map<String, dynamic>?;
        _items = List<Map<String, dynamic>>.from(detalle['items'] as List);
        _tiempoTotal = (detalle['tiempoTotalMin'] as num?)?.toInt() ?? 0;
      });
    } catch (error) {
      if (!mounted) return;
      _mostrarMensaje(
        AppErrorMapper.toUserMessage(
          error,
          fallbackMessage: 'No se pudo cargar el estado de tu pedido.',
        ),
        esError: true,
      );
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  // Abre carta unificada y refresca para reflejar cambios de ítems.
  Future<void> _abrirCarta() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => CartaClientePage(
              mesaId: widget.mesaId,
              numeroMesa: widget.numeroMesa,
            ),
      ),
    );
    await _detenerEscuchaPedidoRealtime();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
  }

  // Recalcula resumen local para evitar recargas completas en ajustes +/-.
  void _recalcularResumenLocal() {
    double subtotal = 0;
    var maxTiempo = 0;

    for (final item in _items) {
      final cantidad = (item['cantidad'] as num?)?.toInt() ?? 0;
      final precio = ((item['precio_unitario'] as num?) ?? 0).toDouble();
      final tiempo = (item['tiempo_elaboracion_min'] as num?)?.toInt() ?? 0;

      if (cantidad <= 0) continue;
      subtotal += precio * cantidad;
      if (tiempo > maxTiempo) {
        maxTiempo = tiempo;
      }
    }

    _tiempoTotal = maxTiempo;

    if (_pedido != null) {
      final estado = (_pedido!['estado'] as String?) ?? 'sin_pedido';
      final actualizado = Map<String, dynamic>.from(_pedido!);
      actualizado['subtotal'] = subtotal;
      if (estado == 'borrador' || estado == 'rechazado_mozo') {
        actualizado['total'] = subtotal;
      }
      _pedido = actualizado;
    }
  }

  // Incrementa/decrementa cantidad en un ítem del pedido actual.
  Future<void> _cambiarCantidad(Map<String, dynamic> item, int delta) async {
    final pedido = _pedido;
    if (pedido == null) return;

    final itemId = item['id'] as String;
    final index = _items.indexWhere((e) => e['id'] == itemId);
    if (index < 0) return;

    final snapshotItems =
        _items.map((e) => Map<String, dynamic>.from(e)).toList();
    final snapshotPedido =
        _pedido == null ? null : Map<String, dynamic>.from(_pedido!);
    final snapshotTiempo = _tiempoTotal;

    final actual = (_items[index]['cantidad'] as num).toInt();
    final nuevaCantidad = actual + delta;

    setState(() => _procesando = true);
    try {
      setState(() {
        if (nuevaCantidad <= 0) {
          _items.removeAt(index);
        } else {
          _items[index]['cantidad'] = nuevaCantidad;
        }
        _recalcularResumenLocal();
      });

      await _repo.cambiarCantidadItem(
        pedidoId: pedido['id'] as String,
        itemId: itemId,
        nuevaCantidad: nuevaCantidad,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _items = snapshotItems;
        _pedido = snapshotPedido;
        _tiempoTotal = snapshotTiempo;
      });
      _mostrarMensaje(
        AppErrorMapper.toUserMessage(
          error,
          fallbackMessage: 'No se pudo actualizar la cantidad.',
        ),
        esError: true,
      );
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  // Envía el pedido para validación del mozo.
Future<void> _enviarPedido() async {
  final pedido = _pedido;
  if (pedido == null) return;

  setState(() => _procesando = true);
  try {
    await _repo.enviarPedidoAMozo(pedido['id'] as String);
    if (!mounted) return;

    
    try {
      await Supabase.instance.client.functions.invoke(
        'notificar-pedido-cliente',
        body: {
          'numeroMesa': widget.numeroMesa,
          'pedidoId': pedido['id'],
        },
      );
    } catch (_) {}

    _mostrarMensaje(
      'Pedido enviado al mozo para confirmación.',
      esError: false,
    );
    await _cargar();
  } catch (error) {
    if (!mounted) return;
    _mostrarMensaje(
      AppErrorMapper.toUserMessage(
        error,
        fallbackMessage: 'No se pudo enviar el pedido.',
      ),
      esError: true,
    );
  } finally {
    if (mounted) setState(() => _procesando = false);
  }
}

  // Cliente confirma recepción luego de entrega del mozo.
  Future<void> _confirmarRecepcion() async {
    final pedido = _pedido;
    if (pedido == null) return;

    setState(() => _procesando = true);
    try {
      await _repo.confirmarRecepcionCliente(pedido['id'] as String);
      if (!mounted) return;
      _mostrarMensaje('Recepción confirmada.', esError: false);
      await _cargar();
    } catch (error) {
      if (!mounted) return;
      _mostrarMensaje(
        AppErrorMapper.toUserMessage(
          error,
          fallbackMessage: 'No se pudo confirmar la recepción.',
        ),
        esError: true,
      );
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  // Cliente solicita cuenta al mozo (paso previo al pago simulado).
Future<void> _solicitarCuenta() async {
  final pedido = _pedido;
  if (pedido == null) return;

  setState(() => _procesando = true);
  try {
    await _repo.solicitarCuenta(pedido['id'] as String);

    //  Notificar al mozo
    try {
      await Supabase.instance.client.functions.invoke(
        'notificar-sector',
        body: {
          'sector': 'mozo',
          'numeroMesa': widget.numeroMesa.toString(),
          'mensaje': '🧾 La mesa ${widget.numeroMesa} solicita la cuenta',
        },
      );
    } catch (_) {}

    if (!mounted) return;
    _mostrarMensaje('Cuenta solicitada al mozo.', esError: false);
    await _cargar();
  } catch (error) {
    if (!mounted) return;
    _mostrarMensaje(
      AppErrorMapper.toUserMessage(
        error,
        fallbackMessage: 'No se pudo solicitar la cuenta.',
      ),
      esError: true,
    );
  } finally {
    if (mounted) setState(() => _procesando = false);
  }
}

  // Simula escaneo de QR de propina con opciones cerradas por consigna.
Future<void> _simularPagoConPropina() async {
  final pedido = _pedido;
  if (pedido == null) return;
 
  // Abre el scanner de QR de propina
  final seleccion = await Navigator.of(context).push<int>(
    MaterialPageRoute(builder: (_) => const PropinaScannerPage()),
  );
 
  // Si el usuario cerró sin escanear, no hace nada
  if (seleccion == null) return;
 
  setState(() => _procesando = true);
  try {
    final resumen = await _repo.prepararPagoConPropina(
      pedidoId: pedido['id'] as String,
      propinaPorcentaje: seleccion,
    );
    if (!mounted) return;
 
    // Notificar al mozo, dueño y supervisor
    try {
      await Supabase.instance.client.functions.invoke(
        'notificar-pago-cliente',
        body: {
          'numeroMesa': widget.numeroMesa,
          'total': resumen['total'],
        },
      );
    } catch (_) {}
 
    _mostrarMensaje(
      'Pago simulado enviado. Total: \$${(resumen['total'] as num).toStringAsFixed(2)}',
      esError: false,
    );
    await _cargar();
  } catch (error) {
    if (!mounted) return;
    _mostrarMensaje(
      AppErrorMapper.toUserMessage(
        error,
        fallbackMessage: 'No se pudo registrar el pago simulado.',
      ),
      esError: true,
    );
  } finally {
    if (mounted) setState(() => _procesando = false);
  }
}
  // Muestra desglose completo de cuenta: ítems, descuento, propina y total.
  Future<void> _mostrarDetalleCuenta() async {
    setState(() => _procesando = true);
    try {
      final detalle = await _repo.getDetalleCuenta(widget.mesaId);
      if (!mounted) return;

      final lineas = List<Map<String, dynamic>>.from(
        detalle['lineas'] as List<Map<String, dynamic>>? ?? const [],
      );
      final estadoCuenta = detalle['estado']?.toString() ?? 'sin_pedido';
      final emitidoAt = DateTime.tryParse(
        detalle['emitidoAt']?.toString() ?? '',
      );
      final descuentoPorcentaje =
          ((detalle['descuentoPorcentaje'] as num?) ?? 0).toDouble();
      final montoDescuento =
          ((detalle['montoDescuento'] as num?) ?? 0).toDouble();
      final propinaPorcentaje =
          ((detalle['propinaPorcentaje'] as num?) ?? 0).toDouble();
      final montoPropina = ((detalle['montoPropina'] as num?) ?? 0).toDouble();
      final total = ((detalle['total'] as num?) ?? 0).toDouble();

      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: const Color(0xFF7A2021),
        isScrollControlled: true,
        builder: (context) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Detalle de la cuenta',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Estado: ${_estadoLegible(estadoCuenta)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          'Emitida: ${_formatearFechaHora(emitidoAt)}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (lineas.isEmpty)
                    const Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 18,
                      ),
                      child: Text(
                        'No hay ítems en la cuenta.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  else
                    SizedBox(
                      height: 220,
                      child: ListView.separated(
                        itemCount: lineas.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          final linea = lineas[index];
                          return Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${linea['nombre']} x${linea['cantidad']}',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                Text(
                                  '\$${((linea['importe'] as num?) ?? 0).toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 10),
                  _FilaCuenta(
                    titulo:
                        'Descuento por juego (${descuentoPorcentaje.toStringAsFixed(0)}%)',
                    valor: -montoDescuento,
                    color: const Color(0xFFB8F5C3),
                  ),
                  _FilaCuenta(
                    titulo:
                        'Propina (${propinaPorcentaje.toStringAsFixed(0)}%)',
                    valor: montoPropina,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D6A4F),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'TOTAL A ABONAR: \$${total.toStringAsFixed(2)}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 30,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (error) {
      if (!mounted) return;
      _mostrarMensaje(
        AppErrorMapper.toUserMessage(
          error,
          fallbackMessage: 'No se pudo cargar el detalle de la cuenta.',
        ),
        esError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _procesando = false);
      }
    }
  }

  Widget _propinaTile(BuildContext context, int porcentaje, String texto) {
    return ListTile(
      title: Text(
        '$texto - $porcentaje%',
        style: const TextStyle(color: Colors.white),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.white),
      onTap: () => Navigator.of(context).pop(porcentaje),
    );
  }

  void _mostrarMensaje(String mensaje, {required bool esError}) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor:
              esError ? const Color(0xFF992E2E) : const Color(0xFF2D6A4F),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final estado = (_pedido?['estado'] as String?) ?? 'sin_pedido';
    final editable = estado == 'borrador' || estado == 'rechazado_mozo';
    final total = ((_pedido?['total'] as num?) ?? 0).toDouble();
    final encuestaCompletada = _pedido?['encuesta_completada'] == true;

    return Scaffold(
      appBar: AppBar(title: Text('Pedido mesa ${widget.numeroMesa}')),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF5B1718), Color(0xFF7A2021)],
          ),
        ),
        child: SafeArea(
          child:
              _cargando
                  ? const Center(child: LogoSpinner(size: 72, strokeWidth: 4))
                  : Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _DatoHeader(
                                    titulo: 'Estado',
                                    valor: _estadoLegible(estado),
                                  ),
                                ),
                                Expanded(
                                  child: _DatoHeader(
                                    titulo: 'Tiempo total',
                                    valor: '$_tiempoTotal minutos',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2D6A4F),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'TOTAL: \$${total.toStringAsFixed(2)}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 34,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                            if ((_pedido?['observaciones_rechazo'] as String?)
                                    ?.isNotEmpty ==
                                true)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  'Motivo de rechazo: ${_pedido!['observaciones_rechazo']}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: FilledButton.icon(
                          onPressed: _procesando ? null : _abrirCarta,
                          icon: const Icon(Icons.restaurant_menu),
                          label: const Text('Agregar productos'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child:
                            _items.isEmpty
                                ? const Center(
                                  child: Text(
                                    'Aún no hay productos en el pedido.',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                )
                                : ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    0,
                                    16,
                                    10,
                                  ),
                                  itemCount: _items.length,
                                  separatorBuilder:
                                      (_, __) => const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    final item = _items[index];
                                    final cantidad =
                                        (item['cantidad'] as num).toInt();
                                    return Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.white24,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item['nombre_snapshot']
                                                          ?.toString() ??
                                                      '',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  '\$${((item['precio_unitario'] as num?) ?? 0).toStringAsFixed(2)}',
                                                  style: const TextStyle(
                                                    color: Colors.white70,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (editable)
                                            Row(
                                              children: [
                                                IconButton(
                                                  onPressed:
                                                      _procesando
                                                          ? null
                                                          : () =>
                                                              _cambiarCantidad(
                                                                item,
                                                                -1,
                                                              ),
                                                  icon: const Icon(
                                                    Icons.remove_circle,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                Text(
                                                  '$cantidad',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                IconButton(
                                                  onPressed:
                                                      _procesando
                                                          ? null
                                                          : () =>
                                                              _cambiarCantidad(
                                                                item,
                                                                1,
                                                              ),
                                                  icon: const Icon(
                                                    Icons.add_circle,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            )
                                          else
                                            Text(
                                              'x$cantidad',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          children: [
                            if (editable)
                              _AccionPrincipal(
                                texto: 'Enviar pedido al mozo',
                                onPressed: _procesando ? null : _enviarPedido,
                                loading: _procesando,
                              ),
                            if (estado == 'entregado_por_mozo')
                              _AccionPrincipal(
                                texto: 'Confirmar recepción',
                                onPressed:
                                    _procesando ? null : _confirmarRecepcion,
                                loading: _procesando,
                              ),
                            if (estado == 'recibido_cliente' ||
                                estado == 'cuenta_solicitada' ||
                                estado == 'pago_pendiente_confirmacion') ...[
                              _AccionPrincipal(
                                texto: 'Ver detalle de cuenta',
                                onPressed:
                                    _procesando ? null : _mostrarDetalleCuenta,
                                loading: false,
                              ),
                              const SizedBox(height: 8),
                              _AccionPrincipal(
                                texto:
                                    estado == 'recibido_cliente'
                                        ? 'Solicitar cuenta'
                                        : 'Cuenta solicitada',
                                onPressed:
                                    estado == 'recibido_cliente' && !_procesando
                                        ? _solicitarCuenta
                                        : null,
                                loading: _procesando,
                              ),
                              const SizedBox(height: 8),
                              _AccionPrincipal(
                                texto: 'QR de propina y pago simulado',
                                onPressed:
                                    (estado == 'cuenta_solicitada' &&
                                            !_procesando)
                                        ? _simularPagoConPropina
                                        : null,
                                loading: false,
                              ),
                              const SizedBox(height: 8),
                              _AccionPrincipal(
                                texto:
                                    encuestaCompletada
                                        ? 'Encuesta ya completada'
                                        : 'Completar encuesta',
                                onPressed:
                                    encuestaCompletada
                                        ? null
                                        : () async {
                                          if (_pedido == null) return;
                                          await Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder:
                                                  (_) => EncuestaClientePage(
                                                    pedidoId:
                                                        _pedido!['id']
                                                            as String,
                                                  ),
                                            ),
                                          );
                                          await _cargar();
                                        },
                                loading: false,
                              ),
                              const SizedBox(height: 8),
                              _AccionPrincipal(
                                texto: 'Ver resultados de encuestas',
                                onPressed:
                                    () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder:
                                            (_) =>
                                                const ResultadosEncuestasPage(),
                                      ),
                                    ),
                                loading: false,
                              ),
                              const SizedBox(height: 8),
                              const _AccionPrincipal(
                                texto: 'Juegos (a cargo de otro módulo)',
                                onPressed: null,
                                loading: false,
                              ),
                            ],
                            if (estado == 'pago_pendiente_confirmacion')
                              const Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Text(
                                  'Pago enviado. Esperando confirmación del mozo.',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ),
                            if (estado == 'cerrado')
                              const Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Text(
                                  'Mesa liberada. Flujo finalizado.',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
        ),
      ),
    );
  }

  String _estadoLegible(String estado) {
    switch (estado) {
      case 'borrador':
        return 'Borrador';
      case 'pendiente_mozo':
        return 'Esperando mozo';
      case 'rechazado_mozo':
        return 'Rechazado por mozo';
      case 'confirmado_mozo':
        return 'Confirmado';
      case 'en_preparacion':
        return 'En preparación';
      case 'listo_para_entrega':
        return 'Listo para entrega';
      case 'entregado_por_mozo':
        return 'Entregado';
      case 'recibido_cliente':
        return 'Recibido por cliente';
      case 'cuenta_solicitada':
        return 'Cuenta solicitada';
      case 'pago_pendiente_confirmacion':
        return 'Pago pendiente';
      case 'cerrado':
        return 'Cerrado';
      default:
        return 'Sin pedido';
    }
  }

  String _formatearFechaHora(DateTime? fecha) {
    return BuenosAiresTime.formatDateTime(fecha);
  }
}

class _DatoHeader extends StatelessWidget {
  const _DatoHeader({required this.titulo, required this.valor});

  final String titulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 11,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          valor,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 18, 
          ),
        ),
      ],
    );
  }
}

class _AccionPrincipal extends StatelessWidget {
  const _AccionPrincipal({
    required this.texto,
    required this.onPressed,
    required this.loading,
  });

  final String texto;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(46),
          backgroundColor: const Color(0xFF2D6A4F),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFE8D7B3),
          disabledForegroundColor: const Color(0xFF4A2B1A),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
        onPressed: onPressed,
        child:
            loading ? const LogoSpinner(size: 18, strokeWidth: 2) : Text(texto),
      ),
    );
  }
}

class _FilaCuenta extends StatelessWidget {
  const _FilaCuenta({
    required this.titulo,
    required this.valor,
    this.color = Colors.white,
  });

  final String titulo;
  final double valor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(titulo, style: const TextStyle(color: Colors.white70)),
          ),
          Text(
            '${valor < 0 ? '-' : ''}\$${valor.abs().toStringAsFixed(2)}',
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}


