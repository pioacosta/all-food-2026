import 'package:all_food/src/features/mesas/presentation/pages/mesa_cliente_acceso_page.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:all_food/src/features/carta/presentation/pages/carta_cliente.dart';
import 'package:all_food/src/features/pedidos/data/repositories/pedidos_repository.dart';
import 'package:all_food/src/features/pedidos/presentation/widgets/cierre_countdown_dialog.dart';
import 'package:all_food/src/shared/errors/app_error_mapper.dart';
// import 'package:all_food/src/shared/utils/buenos_aires_time.dart';
import 'package:all_food/src/shared/widgets/logo_spinner.dart';
import 'package:all_food/src/shared/utils/error_feedback.dart';
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
  bool _propinaAsignada = false;
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

      if (estadoNuevo == 'confirmado_mozo' && !_redireccionando && mounted) {
        _redireccionando = true;
        await _detenerEscuchaPedidoRealtime();
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder:
                (_) => MesaClienteAccesoPage(
                  mesa: {'id': widget.mesaId, 'numero': widget.numeroMesa},
                ),
          ),
        );
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

  // Carga pedido + ?f?tems + tiempo estimado acumulado.
  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      // incluirCerrado: false (default) ??,???? si la page abre y hay un cerrado viejo, lo ignora
      final detalle = await _repo.getDetallePedido(widget.mesaId);
      if (!mounted) return;

      final estadoNuevo =
          (detalle['pedido'] as Map<String, dynamic>?)?['estado'] as String?;

      // Con incluirCerrado: false esto nunca ser?f? 'cerrado', pero por seguridad:
      if (estadoNuevo == 'cerrado') {
        _pedido = detalle['pedido'] as Map<String, dynamic>?;
        await _verificarCierreYRedirigir();
        return;
      }

      setState(() {
        _pedido = detalle['pedido'] as Map<String, dynamic>?;
        _items = List<Map<String, dynamic>>.from(detalle['items'] as List);
        _tiempoTotal = (detalle['tiempoTotalMin'] as num?)?.toInt() ?? 0;
        _propinaAsignada = (_pedido?['propina_porcentaje'] as num?) != null;
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

  // Abre carta unificada y refresca para reflejar cambios de ?f?tems.
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

  // Incrementa/decrementa cantidad en un ?f?tem del pedido actual.
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

  // Env?f?a el pedido para validaci?f?n del mozo.
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
          body: {'numeroMesa': widget.numeroMesa, 'pedidoId': pedido['id']},
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

  // Cliente confirma recepci?f?n luego de entrega del mozo.
  Future<void> _confirmarRecepcion() async {
    final pedido = _pedido;
    if (pedido == null) return;

    setState(() => _procesando = true);
    try {
      await _repo.confirmarRecepcionCliente(pedido['id'] as String);
      if (!mounted) return;
      await _detenerEscuchaPedidoRealtime();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder:
              (_) => MesaClienteAccesoPage(
                mesa: {'id': widget.mesaId, 'numero': widget.numeroMesa},
              ),
        ),
      );
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
            'mensaje': 'La mesa ${widget.numeroMesa} solicita la cuenta',
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
  Future<void> _escanearQrPropina() async {
    final pedido = _pedido;
    if (pedido == null) return;

    // Abre el scanner de QR de propina
    final seleccion = await Navigator.of(
      context,
    ).push<int>(MaterialPageRoute(builder: (_) => const PropinaScannerPage()));

    // Si el usuario cerr?f? sin escanear, no hace nada
    if (seleccion == null) return;

    setState(() => _procesando = true);
    try {
      final resumen = await _repo.asignarPropinaDesdeQr(
        pedidoId: pedido['id'] as String,
        propinaPorcentaje: seleccion,
      );
      if (!mounted) return;

      _mostrarMensaje(
        'Propina aplicada ($seleccion%). Total actualizado: \$${(resumen['total'] as num).toStringAsFixed(2)}',
        esError: false,
      );
      setState(() => _propinaAsignada = true);
      await _cargar();
    } catch (error) {
      if (!mounted) return;
      _mostrarMensaje(
        AppErrorMapper.toUserMessage(
          error,
          fallbackMessage: 'No se pudo asignar la propina.',
        ),
        esError: true,
      );
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  Future<void> _pagarConConfirmacion() async {
    final pedido = _pedido;
    if (pedido == null) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: const Color(0xFFF5F5DC),
            title: const Text(
              'Confirmar pago',
              style: TextStyle(color: Color(0xFF3D1F1F)),
            ),
            content: const Text(
              '¿Deseas confirmar el pago de la cuenta? Esta acción notificará al mozo para validación final.',
              style: TextStyle(color: Color.fromARGB(255, 51, 26, 26)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Pagar'),
              ),
            ],
          ),
    );

    if (confirmar != true) return;

    setState(() => _procesando = true);
    try {
      final resumen = await _repo.confirmarPagoCliente(pedido['id'] as String);
      if (!mounted) return;

      try {
        await Supabase.instance.client.functions.invoke(
          'notificar-pago-cliente',
          body: {'numeroMesa': widget.numeroMesa, 'total': resumen['total']},
        );
      } catch (_) {}

      _mostrarMensaje(
        'Pago enviado. Total: \$${(resumen['total'] as num).toStringAsFixed(2)}',
        esError: false,
      );
      await _cargar();
    } catch (error) {
      if (!mounted) return;
      _mostrarMensaje(
        AppErrorMapper.toUserMessage(
          error,
          fallbackMessage: 'No se pudo confirmar el pago.',
        ),
        esError: true,
      );
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  void _mostrarMensaje(String mensaje, {required bool esError}) {
    if (esError) {
      ErrorFeedback.vibrate();
    }
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

    final descuentoPct =
        ((_pedido?['descuento_juego_porcentaje'] as num?) ?? 0).toDouble();
    final propinaPct =
        ((_pedido?['propina_porcentaje'] as num?) ?? 0).toDouble();
    final hayDesglose = descuentoPct > 0 || propinaPct > 0;

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
                            // --- Estado y Tiempo (solo si no hay desglose) ---
                            Builder(
                              builder: (_) {
                                final descuentoPct =
                                    ((_pedido?['descuento_juego_porcentaje']
                                                as num?) ??
                                            0)
                                        .toDouble();
                                final propinaPct =
                                    ((_pedido?['propina_porcentaje'] as num?) ??
                                            0)
                                        .toDouble();
                                final hayDesglose =
                                    descuentoPct > 0 || propinaPct > 0;

                                if (hayDesglose) return const SizedBox.shrink();

                                return Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'ESTADO',
                                              style: TextStyle(
                                                color: Colors.white60,
                                                fontSize: 11,
                                                letterSpacing: 0.8,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              _estadoLegible(estado),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w800,
                                                fontSize: 18,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'TIEMPO',
                                              style: TextStyle(
                                                color: Colors.white60,
                                                fontSize: 13,
                                                letterSpacing: 0.8,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              '$_tiempoTotal minutos',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w800,
                                                fontSize: 22,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2D6A4F),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
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
                            ),

                            // --- Desglose descuento por juego ---
                            Builder(
                              builder: (_) {
                                final descuentoPct =
                                    ((_pedido?['descuento_juego_porcentaje']
                                                as num?) ??
                                            0)
                                        .toDouble();
                                final subtotal =
                                    ((_pedido?['subtotal'] as num?) ?? 0)
                                        .toDouble();
                                if (descuentoPct <= 0)
                                  return const SizedBox.shrink();
                                final montoDescuento =
                                    subtotal * descuentoPct / 100;
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Column(
                                    children: [
                                      const Divider(
                                        color: Colors.white38,
                                        height: 12,
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            'Precio sin descuento:',
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 17,
                                            ),
                                          ),
                                          Text(
                                            '\$${subtotal.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 17,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Descuento juego (${descuentoPct.toStringAsFixed(0)}%):',
                                            style: const TextStyle(
                                              color: Color(0xFF90EE90),
                                              fontSize: 17,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            '-\$${montoDescuento.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              color: Color(0xFF90EE90),
                                              fontSize: 17,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),

                            // --- Desglose propina ---
                            Builder(
                              builder: (_) {
                                final propinaPct =
                                    ((_pedido?['propina_porcentaje'] as num?) ??
                                            0)
                                        .toDouble();
                                final subtotal =
                                    ((_pedido?['subtotal'] as num?) ?? 0)
                                        .toDouble();
                                if (propinaPct <= 0)
                                  return const SizedBox.shrink();
                                final descuentoPct =
                                    ((_pedido?['descuento_juego_porcentaje']
                                                as num?) ??
                                            0)
                                        .toDouble();
                                final subtotalConDescuento =
                                    subtotal * (1 - descuentoPct / 100);
                                final montoPropina =
                                    subtotalConDescuento * propinaPct / 100;
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Column(
                                    children: [
                                      const Divider(
                                        color: Colors.white38,
                                        height: 12,
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            descuentoPct > 0
                                                ? 'Subtotal con descuento:'
                                                : 'Subtotal:',
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 17,
                                            ),
                                          ),
                                          Text(
                                            '\$${(descuentoPct > 0 ? subtotalConDescuento : subtotal).toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 17,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Propina (${propinaPct.toStringAsFixed(0)}%):',
                                            style: const TextStyle(
                                              color: Color(0xFFFFD700),
                                              fontSize: 17,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            '+\$${montoPropina.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              color: Color(0xFFFFD700),
                                              fontSize: 17,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            // --- Tiempo (solo si hay desglose) ---
                            Builder(
                              builder: (_) {
                                final descuentoPct =
                                    ((_pedido?['descuento_juego_porcentaje']
                                                as num?) ??
                                            0)
                                        .toDouble();
                                final propinaPct =
                                    ((_pedido?['propina_porcentaje'] as num?) ??
                                            0)
                                        .toDouble();
                                final hayDesglose =
                                    descuentoPct > 0 || propinaPct > 0;

                                if (!hayDesglose)
                                  return const SizedBox.shrink();

                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.access_time,
                                        color: Colors.white60,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$_tiempoTotal minutos',
                                        style: const TextStyle(
                                          color: Colors.white60,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      if (editable ||
                          estado == 'pendiente_mozo' ||
                          estado == 'en_preparacion' ||
                          estado == 'listo_para_entrega' ||
                          estado == 'entregado_por_mozo') ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: FilledButton.icon(
                            onPressed: _procesando ? null : _abrirCarta,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(54),
                              textStyle: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            icon: Icon(
                              editable
                                  ? Icons.restaurant_menu
                                  : Icons.receipt_long,
                            ),
                            label: Text(
                              editable ? 'Agregar productos' : 'Ver productos',
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      const SizedBox(height: 10),
                      if (_items.isEmpty)
                        const Expanded(
                          child: Center(
                            child: Text(
                              'Aún no hay productos en el pedido.',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: _ProductosPaginados(
                            items: _items,
                            editable: editable,
                            procesando: _procesando,
                            onCambiarCantidad: _cambiarCantidad,
                            hayDesglose: hayDesglose,
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
                              // Flujo: solicitar cuenta -> escanear propina -> pagar con confirmacion
                              _AccionPrincipal(
                                texto:
                                    estado == 'recibido_cliente'
                                        ? 'Solicitar cuenta'
                                        : estado == 'cuenta_solicitada'
                                        ? 'Escanear QR de propina'
                                        : 'Pago pendiente de confirmación',
                                onPressed:
                                    estado == 'recibido_cliente' && !_procesando
                                        ? _solicitarCuenta
                                        : estado == 'cuenta_solicitada' &&
                                            !_procesando
                                        ? _escanearQrPropina
                                        : null,
                                loading: _procesando,
                              ),
                              if (estado == 'cuenta_solicitada')
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: _AccionPrincipal(
                                    texto: 'Pagar cuenta',
                                    onPressed:
                                        (_procesando || !_propinaAsignada)
                                            ? null
                                            : _pagarConConfirmacion,
                                    loading: _procesando,
                                  ),
                                ),
                              if (estado == 'pago_pendiente_confirmacion')
                                const Padding(
                                  padding: EdgeInsets.only(top: 8),
                                  child: Text(
                                    'Pago enviado. Esperando confirmación del mozo.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                ),
                            ],
                            if (estado == 'cerrado')
                              const Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Text(
                                  'Mesa liberada. Flujo finalizado.',
                                  textAlign: TextAlign.center,
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
        return 'Sin pedido';
      case 'pendiente_mozo':
        return 'Esperando mozo';
      case 'rechazado_mozo':
        return 'Rechazado';
      case 'confirmado_mozo':
        return 'Confirmado';
      case 'en_preparacion':
        return 'En preparación';
      case 'listo_para_entrega':
        return 'Listo para entrega';
      case 'entregado_por_mozo':
        return 'Entregado';
      case 'recibido_cliente':
        return 'Recibido';
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

class _ProductosPaginados extends StatefulWidget {
  const _ProductosPaginados({
    required this.items,
    required this.editable,
    required this.procesando,
    required this.onCambiarCantidad,
    required this.hayDesglose,
  });

  final List<Map<String, dynamic>> items;
  final bool editable;
  final bool procesando;
  final bool hayDesglose;
  final void Function(Map<String, dynamic> item, int delta) onCambiarCantidad;

  @override
  State<_ProductosPaginados> createState() => _ProductosPaginadosState();
}

class _ProductosPaginadosState extends State<_ProductosPaginados> {
  int _pagina = 0;
  static const _porPagina = 4;

  @override
  void didUpdateWidget(_ProductosPaginados old) {
    super.didUpdateWidget(old);
    // Si la lista se achica (por eliminación), ajustamos la página
    final maxPagina = ((widget.items.length - 1) / _porPagina).floor().clamp(
      0,
      9999,
    );
    if (_pagina > maxPagina) setState(() => _pagina = maxPagina);
  }

  @override
  Widget build(BuildContext context) {
    final totalPaginas = (widget.items.length / _porPagina).ceil().clamp(
      1,
      9999,
    );
    final inicio = _pagina * _porPagina;
    final fin = (inicio + _porPagina).clamp(0, widget.items.length);
    final paginaItems = widget.items.sublist(inicio, fin);

    final cantidadItems = paginaItems.length;
    final paddingVertical =
        cantidadItems == 4 ? (widget.hayDesglose ? 10.0 : 20.0) : 14.0;
    final bottomSpacing =
        cantidadItems == 4 ? (widget.hayDesglose ? 8.0 : 14.0) : 10.0;

    return Column(
      children: [
        // ── Items de la página actual ──────────────────────────────
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children:
                  paginaItems.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final cantidad = (item['cantidad'] as num).toInt();
                    final card = Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: paddingVertical,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['nombre_snapshot']?.toString() ?? '',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 22,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '\$${((item['precio_unitario'] as num?) ?? 0).toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 17,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (widget.editable)
                            Row(
                              children: [
                                IconButton(
                                  onPressed:
                                      widget.procesando
                                          ? null
                                          : () => widget.onCambiarCantidad(
                                            item,
                                            -1,
                                          ),
                                  icon: const Icon(
                                    Icons.remove_circle,
                                    color: Colors.white,
                                    size: 34,
                                  ),
                                ),
                                Text(
                                  '$cantidad',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                IconButton(
                                  onPressed:
                                      widget.procesando
                                          ? null
                                          : () =>
                                              widget.onCambiarCantidad(item, 1),
                                  icon: const Icon(
                                    Icons.add_circle,
                                    color: Colors.white,
                                    size: 34,
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
                                fontSize: 24,
                              ),
                            ),
                        ],
                      ),
                    );
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom:
                            index < paginaItems.length - 1 ? bottomSpacing : 0,
                      ),
                      child: card,
                    );
                  }).toList(),
            ),
          ),
        ),
        // ── Paginador ─────────────────────────────────────────────
        if (totalPaginas > 1)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: IconButton(
                    onPressed:
                        _pagina > 0 ? () => setState(() => _pagina--) : null,
                    icon: Icon(
                      Icons.chevron_left,
                      color: _pagina > 0 ? Colors.white : Colors.white30,
                      size: 40,
                    ),
                  ),
                ),
                Text(
                  '${_pagina + 1} / $totalPaginas',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),
                SizedBox(
                  width: 56,
                  height: 56,
                  child: IconButton(
                    onPressed:
                        _pagina < totalPaginas - 1
                            ? () => setState(() => _pagina++)
                            : null,
                    icon: Icon(
                      Icons.chevron_right,
                      color:
                          _pagina < totalPaginas - 1
                              ? Colors.white
                              : Colors.white30,
                      size: 40,
                    ),
                  ),
                ),
              ],
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
          minimumSize: const Size.fromHeight(58),
          backgroundColor: const Color(0xFF2D6A4F),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFE8D7B3),
          disabledForegroundColor: const Color(0xFF4A2B1A),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
        ),
        onPressed: onPressed,
        child:
            loading ? const LogoSpinner(size: 18, strokeWidth: 2) : Text(texto),
      ),
    );
  }
}
