import 'package:all_food/src/features/pedidos/data/repositories/pedidos_repository.dart';
import 'package:all_food/src/shared/errors/app_error_mapper.dart';
import 'package:all_food/src/shared/widgets/logo_spinner.dart';
import 'package:flutter/material.dart';

class PedidosMozoPage extends StatefulWidget {
  const PedidosMozoPage({super.key});

  @override
  State<PedidosMozoPage> createState() => _PedidosMozoPageState();
}

class _PedidosMozoPageState extends State<PedidosMozoPage> {
  final _repo = PedidosRepository();

  bool _cargando = true;
  bool _procesando = false;
  List<Map<String, dynamic>> _pendientes = [];
  List<Map<String, dynamic>> _listosEntrega = [];
  List<Map<String, dynamic>> _pagosPendientes = [];

  @override
  void initState() {
    super.initState();
    // Carga las tres bandejas operativas del mozo.
    _cargar();
  }

  // Sincroniza pedidos pendientes, listos para entregar y pagos pendientes.
  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final pendientes = await _repo.getPedidosPendientesMozo();
      final listos = await _repo.getPedidosListosEntrega();
      final pagos = await _repo.getPedidosPagoPendiente();
      if (!mounted) return;
      setState(() {
        _pendientes = pendientes;
        _listosEntrega = listos;
        _pagosPendientes = pagos;
      });
    } catch (error) {
      if (!mounted) return;
      _mostrarMensaje(
        AppErrorMapper.toUserMessage(
          error,
          fallbackMessage: 'No se pudieron cargar los pedidos de mozo.',
        ),
        esError: true,
      );
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  // Confirmación inicial del mozo para derivar pedido a sectores.
  Future<void> _confirmarPedido(String pedidoId) async {
    setState(() => _procesando = true);
    try {
      await _repo.confirmarPedido(pedidoId);
      await _cargar();
      if (!mounted) return;
      _mostrarMensaje(
        'Pedido confirmado y enviado a sectores.',
        esError: false,
      );
    } catch (error) {
      if (!mounted) return;
      _mostrarMensaje(
        AppErrorMapper.toUserMessage(
          error,
          fallbackMessage: 'No se pudo confirmar.',
        ),
        esError: true,
      );
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  // Rechaza pedido y devuelve al cliente para corrección.
  Future<void> _rechazarPedido(String pedidoId) async {
    final motivoController = TextEditingController();
    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Rechazar pedido'),
            content: TextField(
              controller: motivoController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Motivo del rechazo',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Rechazar'),
              ),
            ],
          ),
    );

    if (confirmar != true) return;

    setState(() => _procesando = true);
    try {
      await _repo.rechazarPedido(
        pedidoId: pedidoId,
        motivo: motivoController.text,
      );
      await _cargar();
      if (!mounted) return;
      _mostrarMensaje(
        'Pedido rechazado para modificación del cliente.',
        esError: false,
      );
    } catch (error) {
      if (!mounted) return;
      _mostrarMensaje(
        AppErrorMapper.toUserMessage(
          error,
          fallbackMessage: 'No se pudo rechazar.',
        ),
        esError: true,
      );
    } finally {
      motivoController.dispose();
      if (mounted) setState(() => _procesando = false);
    }
  }

  // Marca pedido completo como entregado al cliente.
  Future<void> _marcarEntregado(Map<String, dynamic> pedido) async {
    setState(() => _procesando = true);
    try {
      await _repo.marcarPedidoEntregado(pedido['id'] as String);
      await _cargar();
      if (!mounted) return;
      _mostrarMensaje('Pedido marcado como entregado.', esError: false);
    } catch (error) {
      if (!mounted) return;
      _mostrarMensaje(
        AppErrorMapper.toUserMessage(
          error,
          fallbackMessage: 'No se pudo marcar entregado.',
        ),
        esError: true,
      );
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  // Confirma pago final y libera la mesa para reutilización.
  Future<void> _confirmarPago(Map<String, dynamic> pedido) async {
    final mesa = pedido['mesas'] as Map<String, dynamic>?;
    final numeroMesa = mesa?['numero']?.toString() ?? '-';

    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Confirmar pago'),
            content: Text(
              '¿Confirmar pago de la mesa $numeroMesa y liberar la mesa?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Confirmar'),
              ),
            ],
          ),
    );

    if (confirmar != true) return;

    setState(() => _procesando = true);
    try {
      await _repo.confirmarPagoMozo(
        pedidoId: pedido['id'] as String,
        mesaId: pedido['mesa_id'] as String,
      );
      await _cargar();
      if (!mounted) return;
      _mostrarMensaje('Pago confirmado y mesa liberada.', esError: false);
    } catch (error) {
      if (!mounted) return;
      _mostrarMensaje(
        AppErrorMapper.toUserMessage(
          error,
          fallbackMessage: 'No se pudo confirmar pago.',
        ),
        esError: true,
      );
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  // Modal de control para validar importes antes de cerrar cobro.
  Future<void> _mostrarDetalleCuenta(Map<String, dynamic> pedido) async {
    final mesaId = pedido['mesa_id'] as String?;
    if (mesaId == null) return;

    setState(() => _procesando = true);
    try {
      final detalle = await _repo.getDetalleCuenta(mesaId);
      if (!mounted) return;

      final lineas = List<Map<String, dynamic>>.from(
        detalle['lineas'] as List<Map<String, dynamic>>? ?? const [],
      );
      final subtotal = ((detalle['subtotal'] as num?) ?? 0).toDouble();
      final descuentoPorcentaje =
          ((detalle['descuentoPorcentaje'] as num?) ?? 0).toDouble();
      final montoDescuento =
          ((detalle['montoDescuento'] as num?) ?? 0).toDouble();
      final propinaPorcentaje =
          ((detalle['propinaPorcentaje'] as num?) ?? 0).toDouble();
      final montoPropina = ((detalle['montoPropina'] as num?) ?? 0).toDouble();
      final total = ((detalle['total'] as num?) ?? 0).toDouble();
      final estado = detalle['estado']?.toString() ?? 'sin_pedido';
      final emitidoAt = DateTime.tryParse(
        detalle['emitidoAt']?.toString() ?? '',
      );

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
                    'Detalle de cuenta (mozo)',
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
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Estado: ${_estadoLegible(estado)}',
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
                      padding: EdgeInsets.symmetric(vertical: 14),
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
                              color: Colors.white.withOpacity(0.12),
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
                  _FilaCuentaMozo(titulo: 'Subtotal', valor: subtotal),
                  _FilaCuentaMozo(
                    titulo:
                        'Descuento por juego (${descuentoPorcentaje.toStringAsFixed(0)}%)',
                    valor: -montoDescuento,
                    color: const Color(0xFFB8F5C3),
                  ),
                  _FilaCuentaMozo(
                    titulo:
                        'Propina (${propinaPorcentaje.toStringAsFixed(0)}%)',
                    valor: montoPropina,
                  ),
                  const SizedBox(height: 8),
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
                        fontSize: 20,
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
          fallbackMessage: 'No se pudo cargar el detalle de cuenta.',
        ),
        esError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _procesando = false);
      }
    }
  }

  Future<void> _mostrarDetallePedidoPendiente(
    Map<String, dynamic> pedido,
  ) async {
    final pedidoId = pedido['id'] as String?;
    if (pedidoId == null) return;

    setState(() => _procesando = true);
    try {
      final items = await _repo.getItemsPedidoById(pedidoId);
      if (!mounted) return;

      setState(() => _procesando = false);

      final mesa = pedido['mesas'] as Map<String, dynamic>?;
      final numeroMesa = mesa?['numero']?.toString() ?? '-';
      final cliente = pedido['cliente_nombre']?.toString() ?? 'Cliente';
      final creadoAt = DateTime.tryParse(
        pedido['created_at']?.toString() ?? '',
      );

      final accion = await showModalBottomSheet<_AccionPedidoPendiente>(
        context: context,
        isScrollControlled: true,
        backgroundColor: const Color(0xFF7A2021),
        builder: (_) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Detalle de pedido pendiente',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mesa $numeroMesa',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Cliente: $cliente',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Hora: ${_formatearFechaHora(creadoAt)}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'No hay ítems cargados en el pedido.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 280),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final nombre =
                              item['nombre_snapshot']?.toString() ?? '-';
                          final cantidad =
                              (item['cantidad'] as num?)?.toInt() ?? 0;
                          final precio =
                              ((item['precio_unitario'] as num?) ?? 0)
                                  .toDouble();

                          return Container(
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
                                    '$nombre x$cantidad',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                Text(
                                  '\$${(precio * cantidad).toStringAsFixed(2)}',
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
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cerrar'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed:
                              () => Navigator.of(
                                context,
                              ).pop(_AccionPedidoPendiente.rechazar),
                          child: const Text('Rechazar'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          onPressed:
                              () => Navigator.of(
                                context,
                              ).pop(_AccionPedidoPendiente.confirmar),
                          child: const Text('Confirmar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );

      if (!mounted) return;
      if (accion == _AccionPedidoPendiente.confirmar) {
        await _confirmarPedido(pedidoId);
      } else if (accion == _AccionPedidoPendiente.rechazar) {
        await _rechazarPedido(pedidoId);
      }
    } catch (error) {
      if (!mounted) return;
      _mostrarMensaje(
        AppErrorMapper.toUserMessage(
          error,
          fallbackMessage: 'No se pudo cargar el detalle del pedido.',
        ),
        esError: true,
      );
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  String _estadoLegible(String estado) {
    switch (estado) {
      case 'borrador':
        return 'Borrador';
      case 'pendiente_mozo':
        return 'Pendiente mozo';
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
    if (fecha == null) return '--/-- ----';
    final local = fecha.toLocal();
    final dia = local.day.toString().padLeft(2, '0');
    final mes = local.month.toString().padLeft(2, '0');
    final anio = local.year.toString();
    final hora = local.hour.toString().padLeft(2, '0');
    final minuto = local.minute.toString().padLeft(2, '0');
    return '$dia/$mes/$anio $hora:$minuto';
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
    return Scaffold(
      appBar: AppBar(title: const Text('Panel de mozo')),
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
                  ? const Center(child: LogoSpinner(size: 70, strokeWidth: 4))
                  : Column(
                    children: [
                      Expanded(
                        child: _SeccionPedidos(
                          titulo: 'Pendientes de confirmación',
                          pedidos: _pendientes,
                          onTapPedido:
                              _procesando
                                  ? null
                                  : (pedido) =>
                                      _mostrarDetallePedidoPendiente(pedido),
                          itemBuilder: (pedido) {
                            final mesa =
                                pedido['mesas'] as Map<String, dynamic>?;
                            final numeroMesa =
                                mesa?['numero']?.toString() ?? '-';
                            final cliente =
                                pedido['cliente_nombre']?.toString() ??
                                'Cliente';
                            final fecha = DateTime.tryParse(
                              pedido['created_at']?.toString() ?? '',
                            );

                            return _PedidoCardBase(
                              titulo: 'Mesa $numeroMesa',
                              subtitulo: 'Cliente: $cliente',
                              detalle: 'Hora: ${_formatearFechaHora(fecha)}',
                              badgeTexto: 'Pendiente',
                              badgeColor: const Color(0xFFF59E0B),
                              pie: 'Tocá para ver detalle y confirmar/rechazar',
                            );
                          },
                        ),
                      ),
                      Expanded(
                        child: _SeccionPedidos(
                          titulo: 'Listos para entregar',
                          pedidos: _listosEntrega,
                          itemBuilder: (pedido) {
                            final mesa =
                                pedido['mesas'] as Map<String, dynamic>?;
                            final numeroMesa =
                                mesa?['numero']?.toString() ?? '-';
                            final cliente =
                                pedido['cliente_nombre']?.toString() ??
                                'Cliente';
                            final fecha = DateTime.tryParse(
                              pedido['created_at']?.toString() ?? '',
                            );

                            return _PedidoCardBase(
                              titulo: 'Mesa $numeroMesa',
                              subtitulo: 'Cliente: $cliente',
                              detalle:
                                  'Pedido listo desde ${_formatearFechaHora(fecha)}',
                              badgeTexto: 'Listo',
                              badgeColor: const Color(0xFF22C55E),
                              acciones: [
                                FilledButton(
                                  onPressed:
                                      _procesando
                                          ? null
                                          : () => _marcarEntregado(pedido),
                                  child: const Text('Marcar entregado'),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      Expanded(
                        child: _SeccionPedidos(
                          titulo: 'Pagos a confirmar',
                          pedidos: _pagosPendientes,
                          itemBuilder: (pedido) {
                            final mesa =
                                pedido['mesas'] as Map<String, dynamic>?;
                            final numeroMesa =
                                mesa?['numero']?.toString() ?? '-';
                            final cliente =
                                pedido['cliente_nombre']?.toString() ??
                                'Cliente';
                            final fecha = DateTime.tryParse(
                              pedido['created_at']?.toString() ?? '',
                            );

                            return _PedidoCardBase(
                              titulo: 'Mesa $numeroMesa',
                              subtitulo: 'Cliente: $cliente',
                              detalle:
                                  'Pago informado ${_formatearFechaHora(fecha)}',
                              badgeTexto: 'Pago',
                              badgeColor: const Color(0xFF38BDF8),
                              acciones: [
                                OutlinedButton(
                                  onPressed:
                                      _procesando
                                          ? null
                                          : () => _mostrarDetalleCuenta(pedido),
                                  child: const Text('Ver cuenta'),
                                ),
                                FilledButton(
                                  onPressed:
                                      _procesando
                                          ? null
                                          : () => _confirmarPago(pedido),
                                  child: const Text('Confirmar pago'),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
        ),
      ),
    );
  }
}

class _SeccionPedidos extends StatefulWidget {
  const _SeccionPedidos({
    required this.titulo,
    required this.pedidos,
    required this.itemBuilder,
    this.onTapPedido,
  });

  final String titulo;
  final List<Map<String, dynamic>> pedidos;
  final Widget Function(Map<String, dynamic>) itemBuilder;
  final void Function(Map<String, dynamic>)? onTapPedido;

  @override
  State<_SeccionPedidos> createState() => _SeccionPedidosState();
}

class _SeccionPedidosState extends State<_SeccionPedidos> {
  int _paginaActual = 0;

  @override
  void didUpdateWidget(covariant _SeccionPedidos oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pedidos.isEmpty && _paginaActual != 0) {
      setState(() => _paginaActual = 0);
      return;
    }
    if (widget.pedidos.isNotEmpty && _paginaActual >= widget.pedidos.length) {
      setState(() => _paginaActual = widget.pedidos.length - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.titulo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              if (widget.pedidos.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Text(
                    '${_paginaActual + 1}/${widget.pedidos.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child:
                widget.pedidos.isEmpty
                    ? const Center(
                      child: Text(
                        'Sin elementos',
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                    // Renderiza un pedido por página para evitar overflow vertical
                    // y permitir navegación horizontal tipo snap.
                    : PageView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.pedidos.length,
                      onPageChanged:
                          (index) => setState(() => _paginaActual = index),
                      itemBuilder: (context, index) {
                        final pedido = widget.pedidos[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 2),
                          child: InkWell(
                            onTap:
                                widget.onTapPedido == null
                                    ? null
                                    : () => widget.onTapPedido!(pedido),
                            borderRadius: BorderRadius.circular(10),
                            child: widget.itemBuilder(pedido),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}

class _PedidoCardBase extends StatelessWidget {
  const _PedidoCardBase({
    required this.titulo,
    required this.subtitulo,
    required this.detalle,
    required this.badgeTexto,
    required this.badgeColor,
    this.pie,
    this.acciones = const [],
  });

  final String titulo;
  final String subtitulo;
  final String detalle;
  final String badgeTexto;
  final Color badgeColor;
  final String? pie;
  final List<Widget> acciones;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: badgeColor),
                ),
                child: Text(
                  badgeTexto,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitulo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 2),
          Text(
            detalle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70),
          ),
          if (pie != null) ...[
            const SizedBox(height: 8),
            Text(
              pie!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (acciones.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: acciones),
          ],
        ],
      ),
    );
  }
}

enum _AccionPedidoPendiente { confirmar, rechazar }

class _FilaCuentaMozo extends StatelessWidget {
  const _FilaCuentaMozo({
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
