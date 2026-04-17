import 'package:all_food/src/features/carta/presentation/pages/carta_cliente.dart';
import 'package:all_food/src/features/pedidos/data/repositories/pedidos_repository.dart';
import 'package:all_food/src/features/pedidos/presentation/pages/encuesta_cliente_page.dart';
import 'package:all_food/src/features/pedidos/presentation/pages/resultados_encuestas_page.dart';
import 'package:all_food/src/shared/errors/app_error_mapper.dart';
import 'package:all_food/src/shared/widgets/logo_spinner.dart';
import 'package:flutter/material.dart';

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

  bool _cargando = true;
  bool _procesando = false;
  Map<String, dynamic>? _pedido;
  List<Map<String, dynamic>> _items = [];
  int _tiempoTotal = 0;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final detalle = await _repo.getDetallePedido(widget.mesaId);
      if (!mounted) return;
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
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  Future<void> _abrirCarta(String tipo) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => CartaClientePage(
              tipo: tipo,
              mesaId: widget.mesaId,
              numeroMesa: widget.numeroMesa,
            ),
      ),
    );
    await _cargar();
  }

  Future<void> _cambiarCantidad(Map<String, dynamic> item, int delta) async {
    final pedido = _pedido;
    if (pedido == null) return;

    final actual = (item['cantidad'] as num).toInt();
    final nuevaCantidad = actual + delta;

    setState(() => _procesando = true);
    try {
      await _repo.cambiarCantidadItem(
        pedidoId: pedido['id'] as String,
        itemId: item['id'] as String,
        nuevaCantidad: nuevaCantidad,
      );
      await _cargar();
    } catch (error) {
      if (!mounted) return;
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

  Future<void> _enviarPedido() async {
    final pedido = _pedido;
    if (pedido == null) return;

    setState(() => _procesando = true);
    try {
      await _repo.enviarPedidoAMozo(pedido['id'] as String);
      if (!mounted) return;
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

  Future<void> _solicitarCuenta() async {
    final pedido = _pedido;
    if (pedido == null) return;

    setState(() => _procesando = true);
    try {
      await _repo.solicitarCuenta(pedido['id'] as String);
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

  Future<void> _simularPagoConPropina() async {
    final pedido = _pedido;
    if (pedido == null) return;

    final seleccion = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: const Color(0xFF8D2628),
      builder:
          (context) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'QR de propina (simulado)',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _propinaTile(context, 20, 'Excelente'),
                  _propinaTile(context, 15, 'Muy bueno'),
                  _propinaTile(context, 10, 'Bueno'),
                  _propinaTile(context, 5, 'Regular'),
                  _propinaTile(context, 0, 'Malo'),
                ],
              ),
            ),
          ),
    );

    if (seleccion == null) return;

    setState(() => _procesando = true);
    try {
      final resumen = await _repo.prepararPagoConPropina(
        pedidoId: pedido['id'] as String,
        propinaPorcentaje: seleccion,
      );
      if (!mounted) return;
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
    final subtotal = ((_pedido?['subtotal'] as num?) ?? 0).toDouble();
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
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
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
                                    valor: '$_tiempoTotal min',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _DatoHeader(
                                    titulo: 'Subtotal',
                                    valor: '\$${subtotal.toStringAsFixed(2)}',
                                  ),
                                ),
                                Expanded(
                                  child: _DatoHeader(
                                    titulo: 'Total',
                                    valor: '\$${total.toStringAsFixed(2)}',
                                  ),
                                ),
                              ],
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
                        child: Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed:
                                    _procesando
                                        ? null
                                        : () => _abrirCarta('plato'),
                                icon: const Icon(Icons.restaurant_menu),
                                label: const Text('Agregar platos'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed:
                                    _procesando
                                        ? null
                                        : () => _abrirCarta('bebida'),
                                icon: const Icon(Icons.local_bar),
                                label: const Text('Agregar bebidas'),
                              ),
                            ),
                          ],
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
                                        color: Colors.white.withOpacity(0.1),
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
                                                  '\$${((item['precio_unitario'] as num?) ?? 0).toStringAsFixed(2)} c/u',
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
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        Text(
          valor,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
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
        onPressed: onPressed,
        child:
            loading ? const LogoSpinner(size: 18, strokeWidth: 2) : Text(texto),
      ),
    );
  }
}
