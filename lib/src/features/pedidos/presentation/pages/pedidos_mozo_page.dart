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
    _cargar();
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
                          accionesBuilder:
                              (pedido) => [
                                OutlinedButton(
                                  onPressed:
                                      _procesando
                                          ? null
                                          : () => _rechazarPedido(
                                            pedido['id'] as String,
                                          ),
                                  child: const Text('Rechazar'),
                                ),
                                const SizedBox(width: 8),
                                FilledButton(
                                  onPressed:
                                      _procesando
                                          ? null
                                          : () => _confirmarPedido(
                                            pedido['id'] as String,
                                          ),
                                  child: const Text('Confirmar'),
                                ),
                              ],
                        ),
                      ),
                      Expanded(
                        child: _SeccionPedidos(
                          titulo: 'Listos para entregar',
                          pedidos: _listosEntrega,
                          accionesBuilder:
                              (pedido) => [
                                FilledButton(
                                  onPressed:
                                      _procesando
                                          ? null
                                          : () => _marcarEntregado(pedido),
                                  child: const Text('Marcar entregado'),
                                ),
                              ],
                        ),
                      ),
                      Expanded(
                        child: _SeccionPedidos(
                          titulo: 'Pagos a confirmar',
                          pedidos: _pagosPendientes,
                          accionesBuilder:
                              (pedido) => [
                                FilledButton(
                                  onPressed:
                                      _procesando
                                          ? null
                                          : () => _confirmarPago(pedido),
                                  child: const Text('Confirmar pago'),
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
}

class _SeccionPedidos extends StatelessWidget {
  const _SeccionPedidos({
    required this.titulo,
    required this.pedidos,
    required this.accionesBuilder,
  });

  final String titulo;
  final List<Map<String, dynamic>> pedidos;
  final List<Widget> Function(Map<String, dynamic>) accionesBuilder;

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
          Text(
            titulo,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child:
                pedidos.isEmpty
                    ? const Center(
                      child: Text(
                        'Sin elementos',
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                    : ListView.separated(
                      itemCount: pedidos.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final pedido = pedidos[index];
                        final mesa = pedido['mesas'] as Map<String, dynamic>?;
                        final numeroMesa = mesa?['numero']?.toString() ?? '-';
                        return Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mesa $numeroMesa',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: accionesBuilder(pedido),
                              ),
                            ],
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
