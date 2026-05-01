import 'package:flutter/material.dart';
import 'package:all_food/src/features/pedidos/data/repositories/pedidos_repository.dart';
import 'package:all_food/src/shared/errors/app_error_mapper.dart';
import 'package:all_food/src/shared/utils/buenos_aires_time.dart';
import 'package:all_food/src/shared/widgets/logo_spinner.dart';
import 'package:all_food/src/shared/utils/error_feedback.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PedidosMozoPage extends StatefulWidget {
  const PedidosMozoPage({super.key});

  @override
  State<PedidosMozoPage> createState() => _PedidosMozoPageState();
}

class _PedidosMozoPageState extends State<PedidosMozoPage> {
  final _repo = PedidosRepository();
  RealtimeChannel? _pedidosChannel;

  bool _cargando = true;
  bool _procesando = false;
  bool _sincronizandoRealtime = false;
  List<Map<String, dynamic>> _pendientes = [];
  List<Map<String, dynamic>> _listosEntrega = [];
  List<Map<String, dynamic>> _pagosPendientes = [];

  @override
  void initState() {
    super.initState();
    _cargar();
    _iniciarEscuchaPedidosRealtime();
  }

  @override
  void dispose() {
    _detenerEscuchaPedidosRealtime();
    super.dispose();
  }

  void _iniciarEscuchaPedidosRealtime() {
    final client = Supabase.instance.client;
    _pedidosChannel?.unsubscribe();
    _pedidosChannel =
        client
            .channel('pedidos_mozo_bandejas')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'pedidos',
              callback: (_) {
                if (!mounted || _cargando) return;
                _cargarSilencioso();
              },
            )
            .subscribe();
  }

  Future<void> _detenerEscuchaPedidosRealtime() async {
    final channel = _pedidosChannel;
    _pedidosChannel = null;
    if (channel != null) await channel.unsubscribe();
  }

  Future<void> _cargarSilencioso() async {
    if (_sincronizandoRealtime) return;
    _sincronizandoRealtime = true;
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
    } catch (_) {
      // Silencioso.
    } finally {
      _sincronizandoRealtime = false;
    }
  }

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

  Future<void> _confirmarPedido(String pedidoId) async {
    setState(() => _procesando = true);
    try {
      await _repo.confirmarPedido(pedidoId);
      try {
        final items = await _repo.getItemsPedidoById(pedidoId);
        final tieneComida = items.any(
          (item) => item['tipo_producto']?.toString() == 'plato',
        );
        final tieneBebida = items.any(
          (item) => item['tipo_producto']?.toString() == 'bebida',
        );

        final pedidoData =
            await Supabase.instance.client
                .from('pedidos')
                .select('mesas(numero)')
                .eq('id', pedidoId)
                .single();

        final numeroMesa = pedidoData['mesas']?['numero']?.toString() ?? '-';

        if (tieneComida) {
          await Supabase.instance.client.functions.invoke(
            'notificar-sector',
            body: {
              'sector': 'cocinero',
              'numeroMesa': numeroMesa,
              'mensaje': 'Nuevo pedido de cocina - Mesa $numeroMesa',
            },
          );
        }
        if (tieneBebida) {
          await Supabase.instance.client.functions.invoke(
            'notificar-sector',
            body: {
              'sector': 'cantinero',
              'numeroMesa': numeroMesa,
              'mensaje': 'Nuevo pedido de bar - Mesa $numeroMesa',
            },
          );
        }
      } catch (_) {}

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

  Future<void> _rechazarPedido(String pedidoId) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (_) => Dialog(
            backgroundColor: const Color(0xFFF7ECEC),
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Rechazar pedido',
                    style: TextStyle(
                      color: Color(0xFF2A1414),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'El pedido será rechazado y el cliente podrá modificarlo.',
                    style: TextStyle(
                      color: Color(0xFF3A2222),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF7A2021),
                        ),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 10),
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFB62F2F),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Rechazar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
    if (confirmar != true) return;

    setState(() => _procesando = true);
    try {
      await _repo.rechazarPedido(pedidoId: pedidoId);
      try {
        final pedidoData =
            await Supabase.instance.client
                .from('pedidos')
                .select('cliente_id, mesas(numero)')
                .eq('id', pedidoId)
                .single();

        final clienteId = pedidoData['cliente_id'] as String?;
        final numeroMesa = pedidoData['mesas']?['numero']?.toString() ?? '-';

        if (clienteId != null) {
          await Supabase.instance.client.functions.invoke(
            'notificar-pedido-rechazado',
            body: {'clienteId': clienteId, 'numeroMesa': numeroMesa},
          );
        }
      } catch (_) {}

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
      if (mounted) setState(() => _procesando = false);
    }
  }

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

  Future<void> _confirmarPago(Map<String, dynamic> pedido) async {
    final mesa = pedido['mesas'] as Map<String, dynamic>?;
    final numeroMesa = mesa?['numero']?.toString() ?? '-';

    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (_) => Dialog(
            backgroundColor: const Color(0xFFF7ECEC),
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Confirmar pago',
                    style: TextStyle(
                      color: Color(0xFF2A1414),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
      '¿Confirmar pago de la mesa $numeroMesa y liberar la mesa?',
                    style: const TextStyle(
                      color: Color(0xFF3A2222),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF7A2021),
                        ),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 10),
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF2D6A4F),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Confirmar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
    if (confirmar != true) return;

    setState(() => _procesando = true);
    try {
      await _repo.confirmarPagoMozo(
        pedidoId: pedido['id'] as String,
        mesaId: pedido['mesa_id'] as String,
      );
      try {
        await Supabase.instance.client.functions.invoke(
          'notificar-pago-confirmado',
          body: {'numeroMesa': numeroMesa},
        );
      } catch (_) {}

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
        builder: (_) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Detalle de cuenta',
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
      if (mounted) setState(() => _procesando = false);
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

      final mesa = pedido['mesas'] as Map<String, dynamic>?;
      final numeroMesa = mesa?['numero']?.toString() ?? '-';
      final cliente = pedido['cliente_nombre']?.toString() ?? 'Cliente';
      final creadoAt = DateTime.tryParse(
        pedido['created_at']?.toString() ?? '',
      );

      setState(() => _procesando = false);
      final accion = await Navigator.of(context).push<_AccionPedidoPendiente>(
        MaterialPageRoute(
          builder:
              (_) => _DetallePedidoPendientePage(
                numeroMesa: numeroMesa,
                cliente: cliente,
                hora: _formatearFechaHora(creadoAt),
                items: items,
              ),
        ),
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

  String _formatearFechaHora(DateTime? fecha) =>
      BuenosAiresTime.formatDateTime(fecha);

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
    return Scaffold(
      appBar: AppBar(title: const Text('Gestión')),
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
                  : DefaultTabController(
                    length: 3,
                    child: Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const TabBar(
                            labelColor: Colors.white,
                            unselectedLabelColor: Colors.white70,
                            indicatorColor: Color(0xFFFFDCC7),
                            labelStyle: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                            unselectedLabelStyle: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                            tabs: [
                              Tab(text: 'Pendientes'),
                              Tab(text: 'Listos'),
                              Tab(text: 'Pagos'),
                            ],
                          ),
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              _PendientesList(
                                pedidos: _pendientes,
                                bloqueado: _procesando,
                                formatearFechaHora: _formatearFechaHora,
                                onTap: _mostrarDetallePedidoPendiente,
                              ),
                              _EstadoList(
                                vacio: 'No hay pedidos listos para entregar.',
                                pedidos: _listosEntrega,
                                formatearFechaHora: _formatearFechaHora,
                                actionLabel: 'Marcar entregado',
                                onAction:
                                    _procesando
                                        ? null
                                        : (p) => _marcarEntregado(p),
                              ),
                              _EstadoList(
                                vacio:
                                    'No hay pagos pendientes de confirmación.',
                                pedidos: _pagosPendientes,
                                formatearFechaHora: _formatearFechaHora,
                                actionLabel: 'Confirmar pago',
                                onAction:
                                    _procesando
                                        ? null
                                        : (p) => _confirmarPago(p),
                                secondaryLabel: 'Ver cuenta',
                                onSecondary:
                                    _procesando
                                        ? null
                                        : (p) => _mostrarDetalleCuenta(p),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
        ),
      ),
    );
  }
}

enum _AccionPedidoPendiente { confirmar, rechazar }

class _PendientesList extends StatelessWidget {
  const _PendientesList({
    required this.pedidos,
    required this.bloqueado,
    required this.formatearFechaHora,
    required this.onTap,
  });

  final List<Map<String, dynamic>> pedidos;
  final bool bloqueado;
  final String Function(DateTime? fecha) formatearFechaHora;
  final Future<void> Function(Map<String, dynamic> pedido) onTap;

  @override
  Widget build(BuildContext context) {
    if (pedidos.isEmpty) {
      return const Center(
        child: Text(
          'No hay pedidos pendientes de confirmación.',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
      itemCount: pedidos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final pedido = pedidos[index];
        final mesa = pedido['mesas'] as Map<String, dynamic>?;
        final numeroMesa = mesa?['numero']?.toString() ?? '-';
        final fecha = DateTime.tryParse(pedido['created_at']?.toString() ?? '');
        return InkWell(
          onTap: bloqueado ? null : () => onTap(pedido),
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white24),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  const Icon(
                    Icons.table_restaurant_rounded,
                    color: Color(0xFFFFE8C2),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Mesa $numeroMesa',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    formatearFechaHora(fecha),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right, color: Colors.white),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EstadoList extends StatelessWidget {
  const _EstadoList({
    required this.vacio,
    required this.pedidos,
    required this.formatearFechaHora,
    required this.actionLabel,
    required this.onAction,
    this.secondaryLabel,
    this.onSecondary,
  });

  final String vacio;
  final List<Map<String, dynamic>> pedidos;
  final String Function(DateTime? fecha) formatearFechaHora;
  final String actionLabel;
  final Future<void> Function(Map<String, dynamic>)? onAction;
  final String? secondaryLabel;
  final Future<void> Function(Map<String, dynamic>)? onSecondary;

  @override
  Widget build(BuildContext context) {
    if (pedidos.isEmpty) {
      return Center(
        child: Text(vacio, style: const TextStyle(color: Colors.white70)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
      itemCount: pedidos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final pedido = pedidos[index];
        final mesa = pedido['mesas'] as Map<String, dynamic>?;
        final numeroMesa = mesa?['numero']?.toString() ?? '-';
        final cliente = pedido['cliente_nombre']?.toString() ?? 'Cliente';
        final fecha = DateTime.tryParse(pedido['created_at']?.toString() ?? '');
        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mesa $numeroMesa',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cliente: $cliente',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Hora: ${formatearFechaHora(fecha)}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (secondaryLabel != null && onSecondary != null)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => onSecondary!(pedido),
                          style: OutlinedButton.styleFrom(
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                            minimumSize: const Size.fromHeight(48),
                          ),
                          child: Text(secondaryLabel!),
                        ),
                      ),
                    if (secondaryLabel != null && onSecondary != null)
                      const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed:
                            onAction == null ? null : () => onAction!(pedido),
                        style: FilledButton.styleFrom(
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                          minimumSize: const Size.fromHeight(48),
                        ),
                        child: Text(actionLabel),
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
  }
}

class _DetallePedidoPendientePage extends StatelessWidget {
  const _DetallePedidoPendientePage({
    required this.numeroMesa,
    required this.cliente,
    required this.hora,
    required this.items,
  });

  final String numeroMesa;
  final String cliente;
  final String hora;
  final List<Map<String, dynamic>> items;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de pedido')),
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
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mesa $numeroMesa',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Cliente: $cliente',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Hora: $hora',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child:
                      items.isEmpty
                          ? const Center(
                            child: Text(
                              'Este pedido no tiene ítems.',
                              style: TextStyle(color: Colors.white70),
                            ),
                          )
                          : ListView.separated(
                            itemCount: items.length,
                            separatorBuilder:
                                (_, __) => const SizedBox(height: 8),
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '$nombre x$cantidad',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 22,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '\$${(precio * cantidad).toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 21,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF2D6A4F),
                          minimumSize: const Size.fromHeight(54),
                          textStyle: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        onPressed:
                            () => Navigator.of(
                              context,
                            ).pop(_AccionPedidoPendiente.confirmar),
                        child: const Text('Aceptar'),
                      ),
                    ),
                    const SizedBox(width: 28),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFB62F2F),
                          minimumSize: const Size.fromHeight(54),
                          textStyle: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        onPressed:
                            () => Navigator.of(
                              context,
                            ).pop(_AccionPedidoPendiente.rechazar),
                        child: const Text('Rechazar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
