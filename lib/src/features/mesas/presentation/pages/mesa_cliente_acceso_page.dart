import 'package:all_food/src/features/chat/presentation/pages/chat_page.dart';
import 'package:all_food/src/features/mesas/presentation/widgets/hero_mesa_card.dart';
import 'package:all_food/src/features/pedidos/data/repositories/pedidos_repository.dart';
import 'package:all_food/src/features/pedidos/presentation/pages/encuesta_cliente_page.dart';
import 'package:all_food/src/features/pedidos/presentation/pages/juegos_descuento_page.dart';
import 'package:all_food/src/features/pedidos/presentation/pages/resultados_encuestas_page.dart';
import 'package:all_food/src/features/pedidos/presentation/widgets/cierre_countdown_dialog.dart';
import 'package:all_food/src/shared/theme/app_ui.dart';
import 'package:all_food/src/shared/widgets/logo_spinner.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MesaClienteAccesoPage extends StatefulWidget {
  const MesaClienteAccesoPage({required this.mesa, super.key});
  final Map<String, dynamic> mesa;

  @override
  State<MesaClienteAccesoPage> createState() => _MesaClienteAccesoPageState();
}

class _MesaClienteAccesoPageState extends State<MesaClienteAccesoPage> {
  final _repo = PedidosRepository();
  late final RealtimeChannel _canal;
  bool _cargando = true;
  Map<String, dynamic>? _pedido;
  bool _redireccionando = false;

  static const _estadosConPedidoActivo = {
    'confirmado_mozo',
    'en_preparacion',
    'listo_para_entrega',
    'entregado_por_mozo',
    'recibido_cliente',
    'cuenta_solicitada',
    'pago_pendiente_confirmacion',
  };
  static const _estadosConEncuesta = {
    'recibido_cliente',
    'cuenta_solicitada',
    'pago_pendiente_confirmacion',
  };

  String get _mesaId => widget.mesa['id'] as String;
  int get _numeroMesa => widget.mesa['numero'] as int;

  @override
  void initState() {
    super.initState();
    _cargarPedido();
    _suscribirseAPedido();
  }

  @override
  void dispose() {
    Supabase.instance.client.removeChannel(_canal);
    super.dispose();
  }

  void _suscribirseAPedido() {
    _canal =
        Supabase.instance.client
            .channel('pedidos_changes')
            .onPostgresChanges(
              event: PostgresChangeEvent.update,
              schema: 'public',
              table: 'pedidos',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'mesa_id',
                value: _mesaId,
              ),
              callback: (payload) {
                if (!mounted) return;
                final nuevoEstado = payload.newRecord['estado'] as String?;
                if (nuevoEstado == 'cerrado') {
                  _pedido = payload.newRecord;
                  _verificarCierreYRedirigir();
                  return;
                }
                setState(() => _pedido = payload.newRecord);
              },
            )
            .subscribe();
  }

  Future<void> _cargarPedido() async {
    setState(() => _cargando = true);
    try {
      final detalle = await _repo.getDetallePedido(_mesaId);
      if (!mounted) return;
      
      final pedido = detalle['pedido'] as Map<String, dynamic>?;
      final estado = pedido?['estado'] as String?;
      
      if (estado == 'cerrado') {
        _pedido = pedido;
        await _verificarCierreYRedirigir();
        return;
      }
      
      setState(() => _pedido = pedido);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _navegarY(Future<void> Function() navegar) async {
    await navegar();
    if (!mounted) return;
    await _cargarPedido();
  }

  Future<void> _verificarCierreYRedirigir() async {
    final estado = (_pedido?['estado'] as String?) ?? 'sin_pedido';
    if (estado != 'cerrado' || _redireccionando || !mounted) return;

    _redireccionando = true;
    Supabase.instance.client.removeChannel(_canal);

    await _mostrarModalCierreYRedirigir();
  }

  Future<void> _mostrarModalCierreYRedirigir() async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => CierreCountdownDialog(
        onComplete: () {
          Navigator.of(context).pop();
        },
      ),
    );

    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
  }


  @override
  Widget build(BuildContext context) {
    final clienteId = Supabase.instance.client.auth.currentUser!.id;
    final estado = (_pedido?['estado'] as String?) ?? '';
    final pedidoId = _pedido?['id'] as String?;
    final encuestaCompletada = _pedido?['encuesta_completada'] == true;
    final descuentoActual =
        ((_pedido?['descuento_juego_porcentaje'] as num?) ?? 0).toDouble();

    final tienePedido = _estadosConPedidoActivo.contains(estado);
    final tieneEncuesta = _estadosConEncuesta.contains(estado);

    return Scaffold(
      appBar: AppBar(title: const Text('Mesa validada')),
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppUi.fondoPrincipal),
        child: SafeArea(
          child:
              _cargando
                  ? const Center(child: LogoSpinner(size: 48, strokeWidth: 3))
                  : Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Hero — crece proporcionalmente ───────────────
                        Expanded(
                          flex: 2,
                          child: HeroMesaCard(
                            numeroMesa: _numeroMesa,
                            estado: tienePedido ? estado : null,
                          ),
                        ),

                        // ── Botones — resto del espacio ───────────────────
                        Expanded(
                          flex: 6,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 10),

                              // Grid: Chat mozo + Ver encuestas
                              SizedBox(
                                height: 170,
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: _BtnCuadrado(
                                        icon: Icons.support_agent_rounded,
                                        titulo: 'Chat mozo',
                                        descripcion: 'Consultá al instante',
                                        onTap:
                                            () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (_) => ChatPage(
                                                      mesaId: _mesaId,
                                                      clienteId: clienteId,
                                                    ),
                                              ),
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _BtnCuadrado(
                                        icon: Icons.bar_chart_rounded,
                                        titulo: 'Ver encuestas',
                                        descripcion: 'Qué dicen otros',
                                        onTap:
                                            () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (_) =>
                                                        const ResultadosEncuestasPage(),
                                              ),
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 10),

                              // Juegos (solo con pedido activo)
                              if (tienePedido && pedidoId != null) ...[
                                Expanded(
                                  flex: 1,
                                  child: _BtnWide(
                                    icon: Icons.sports_esports_rounded,
                                    titulo: 'Juegos y descuentos',
                                    descripcion: 'Jugá mientras esperás y ganá beneficios',
                                    bgColor: const Color(0xFFE8F5E2),
                                    iconColor: const Color(0xFF3B6D11),
                                    onTap: () => _navegarY( () => Navigator.push(context,
                                      MaterialPageRoute(
                                        builder:(_,) => JuegosDescuentoPage(pedidoId: pedidoId, descuentoActual: descuentoActual),
                                      ),
                                    )
                                    as Future<void>,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                              ],

                              // Encuesta (solo estados avanzados)
                              if (tieneEncuesta && pedidoId != null) ...[
                                Expanded(
                                  flex: 1,
                                  child: _BtnWide(
                                    icon:
                                        encuestaCompletada
                                            ? Icons.check_circle_rounded
                                            : Icons
                                                .sentiment_satisfied_alt_rounded,
                                    titulo: encuestaCompletada ? 'Encuesta completada' : 'Completar encuesta',
                                    descripcion: encuestaCompletada ? '¡Gracias por tu opinión!' : 'Tu feedback nos ayuda a mejorar',
                                    iconColor: encuestaCompletada ? AppUi.exito : null,
                                    onTap:
                                        encuestaCompletada
                                            ? () {}
                                            : () => _navegarY(
                                              () =>
                                                  Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder:
                                                              (_) =>
                                                                  EncuestaClientePage(
                                                                    pedidoId:
                                                                        pedidoId,
                                                                  ),
                                                        ),
                                                      )
                                                      as Future<void>,
                                            ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                              ],

                              // ── ESTADO DEL PEDIDO — flex:1 cuando no hay pedido 
                              // ── VER CARTA       — flex:2 cuando no hay pedido (protagonista) ─
                              if (!tienePedido) ...[
                                Expanded(
                                  flex: 1,
                                  child: _BtnPrincipal(
                                    icon: Icons.pending_actions_rounded,
                                    titulo: 'Estado del pedido',
                                    descripcion: 'Todavía no hay pedido activo',
                                    esPrimario: false, 
                                    onTap:
                                        () => _navegarY(
                                          () =>
                                              Navigator.pushNamed(
                                                    context,
                                                    '/pedido-cliente',
                                                    arguments: {
                                                      'mesaId': _mesaId,
                                                      'numeroMesa': _numeroMesa,
                                                    },
                                                  )
                                                  as Future<void>,
                                        ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Expanded(
                                  flex: 2, 
                                  child: _BtnPrincipal(
                                    icon: Icons.restaurant_menu_rounded,
                                    titulo: 'Ver carta',
                                    descripcion:
                                        'Explorá el menú y armá tu pedido',
                                    esPrimario: true, 
                                    onTap:
                                        () => Navigator.pushNamed(
                                          context,
                                          '/carta-cliente',
                                          arguments: {
                                            'mesaId': _mesaId,
                                            'numeroMesa': _numeroMesa,
                                          },
                                        ),
                                  ),
                                ),
                              ] else ...[
                                Expanded(
                                  flex: 2,
                                  child: _BtnPrincipal(
                                    icon: Icons.pending_actions_rounded,
                                    titulo: 'Estado del pedido',
                                    descripcion:
                                        'Seguí tu pedido en tiempo real',
                                    esPrimario: false, 
                                    onTap:
                                        () => _navegarY(
                                          () =>
                                              Navigator.pushNamed(
                                                    context,
                                                    '/pedido-cliente',
                                                    arguments: {
                                                      'mesaId': _mesaId,
                                                      'numeroMesa': _numeroMesa,
                                                    },
                                                  )
                                                  as Future<void>,
                                        ),
                                  ),
                                ),
                              ],
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

// Botón cuadrado (grid 2x2) — Chat mozo y Ver encuestas
class _BtnCuadrado extends StatelessWidget {
  const _BtnCuadrado({
    required this.icon,
    required this.titulo,
    required this.descripcion,
    required this.onTap,
  });

  final IconData icon;
  final String titulo;
  final String descripcion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(14),
          height: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFF0E4D0),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF5C1F1F).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: const Color(0xFF5C1F1F), size: 30),
              ),
              const SizedBox(height: 8),
              Text(
                titulo,
                style: const TextStyle(
                  color: Color(0xFF3A1010),
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                descripcion,
                style: const TextStyle(
                  color: Color(0xFF7A4040),
                  fontSize: 15,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Botón wide secundario — Juegos y Encuesta
class _BtnWide extends StatelessWidget {
  const _BtnWide({
    required this.icon,
    required this.titulo,
    required this.descripcion,
    required this.onTap,
    this.iconColor,
    this.bgColor,
  });

  final IconData icon;
  final String titulo;
  final String descripcion;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? bgColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: bgColor ?? const Color(0xFFF0E4D0),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: (iconColor ?? const Color(0xFF5C1F1F)).withValues(
                    alpha: 0.12,
                  ),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? const Color(0xFF5C1F1F),
                  size: 30,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      titulo,
                      style: TextStyle(
                        color:
                            iconColor != null
                                ? Color.lerp(iconColor, Colors.black, 0.6)!
                                : const Color(0xFF3A1010),
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      descripcion,
                      style: TextStyle(
                        color: (iconColor ?? const Color(0xFF7A4040))
                            .withValues(alpha: 0.7),
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: const Color(0xFF5C1F1F).withValues(alpha: 0.25),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Botón principal — Ver carta / Estado del pedido
class _BtnPrincipal extends StatelessWidget {
  const _BtnPrincipal({
    required this.icon,
    required this.titulo,
    required this.descripcion,
    required this.onTap,
    required this.esPrimario, 
  });

  final IconData icon;
  final String titulo;
  final String descripcion;
  final VoidCallback onTap;
  final bool esPrimario;

  @override
  Widget build(BuildContext context) {
    final bg = esPrimario ? const Color(0xFFFFBD88 ) : const Color(0xFF5C1F1F);
    final textColor = esPrimario ? const Color(0xFF5C1F1F) : AppUi.texto;
    final subColor =
        esPrimario
            ? const Color(0xFF2C1A1A).withValues(alpha: 0.55)
            : AppUi.textoSecundario.withValues(alpha: 0.5);
    final iconBg =
        esPrimario
            ? const Color(0xFF2C1A1A).withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.1);
    final chevColor =
        esPrimario
            ? const Color(0xFF2C1A1A).withValues(alpha: 0.35)
            : Colors.white.withValues(alpha: 0.25);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(18),
            border:
                esPrimario
                    ? null
                    : Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: textColor, size: 50),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      titulo,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      descripcion,
                      style: TextStyle(color: subColor, fontSize: 17),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: chevColor, size: 30),
            ],
          ),
        ),
      ),
    );
  }
}
