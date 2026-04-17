import 'package:all_food/src/features/mesas/data/repositories/mesas_repository.dart';
import 'package:all_food/src/features/mesas/presentation/pages/mesa_qr_scanner_page.dart';
import 'package:flutter/material.dart';
import 'package:all_food/src/features/home/data/repositories/home_repository.dart';
import 'package:all_food/src/shared/errors/app_error_mapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/widgets/logo_spinner.dart';
import '../../../auth/presentation/pages/login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({required this.supabaseReady, super.key});

  final bool supabaseReady;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  var _cerrandoSesion = false;
  var _solicitandoMesa = false;
  bool _cargandoPerfil = true;
  bool _cargandoEstadoMesaCliente = false;
  String? _perfil;
  String _estadoMesaCliente = 'sin_solicitud';
  Map<String, dynamic>? _mesaAsignada;
  RealtimeChannel? _notificacionesChannel;
  String? _ultimaNotificacionId;
  final _homeRepository = HomeRepository();
  final _mesasRepository = MesasRepository();

  // List<Map<String, dynamic>> _mesasOcupadas = [];

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  Future<void> _cargarPerfil() async {
    if (!widget.supabaseReady) {
      setState(() {
        _perfil = null;
        _cargandoPerfil = false;
      });
      return;
    }

    try {
      final perfil = await _homeRepository.getCurrentUserRole();
      if (!mounted) return;
      setState(() {
        _perfil = perfil;
        _cargandoPerfil = false;
      });

      _iniciarEscuchaNotificaciones();

      if (_esPerfilCliente(perfil)) {
        await _refrescarEstadoMesaCliente();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _perfil = null;
        _cargandoPerfil = false;
      });
    }
  }

  bool _esPerfilCliente(String? perfil) {
    return perfil == 'cliente_registrado' || perfil == 'cliente_anonimo';
  }

  Future<void> _refrescarEstadoMesaCliente() async {
    if (!_esPerfilCliente(_perfil)) return;

    setState(() => _cargandoEstadoMesaCliente = true);
    try {
      final estado = await _mesasRepository.getEstadoMesaClienteActual();
      if (!mounted) return;
      setState(() {
        _estadoMesaCliente = estado['estado'] as String? ?? 'sin_solicitud';
        _mesaAsignada = estado['mesa'] as Map<String, dynamic>?;
      });
    } catch (error) {
      if (!mounted) return;
      _mostrarMensaje(
        AppErrorMapper.toUserMessage(
          error,
          fallbackMessage: 'No fue posible consultar el estado de tu mesa.',
        ),
        esError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _cargandoEstadoMesaCliente = false);
      }
    }
  }

  Future<void> _solicitarMesa() async {
    if (_solicitandoMesa) return;

    setState(() => _solicitandoMesa = true);
    try {
      await _mesasRepository.solicitarMesaClienteActual();
      if (!mounted) return;
      _mostrarMensaje(
        'Solicitud enviada. Espera a que el metre te asigne una mesa.',
        esError: false,
      );
      await _refrescarEstadoMesaCliente();
    } catch (error) {
      if (!mounted) return;
      _mostrarMensaje(
        AppErrorMapper.toUserMessage(
          error,
          fallbackMessage: 'No se pudo solicitar la mesa.',
        ),
        esError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _solicitandoMesa = false);
      }
    }
  }

  Future<void> _cerrarSesion() async {
    if (_cerrandoSesion) return;
    setState(() => _cerrandoSesion = true);

    try {
      await _detenerEscuchaNotificaciones();
      if (widget.supabaseReady) {
        await _homeRepository.signOut();
      }

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder:
              (_) => LoginPage(
                supabaseReady: widget.supabaseReady,
                successMessage: 'Sesión cerrada correctamente.',
              ),
        ),
        (route) => false,
      );
    } catch (error) {
      if (!mounted) return;
      _mostrarMensaje(
        AppErrorMapper.toUserMessage(
          error,
          fallbackMessage: 'No fue posible cerrar sesión.',
        ),
        esError: true,
      );
    } finally {
      if (mounted) setState(() => _cerrandoSesion = false);
    }
  }

  void _iniciarEscuchaNotificaciones() {
    if (!widget.supabaseReady) return;

    final client = Supabase.instance.client;
    final uid = client.auth.currentUser?.id;
    if (uid == null) return;

    _notificacionesChannel?.unsubscribe();

    _notificacionesChannel =
        client
            .channel('notificaciones_$uid')
            .onPostgresChanges(
              event: PostgresChangeEvent.insert,
              schema: 'public',
              table: 'notificaciones',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'destinatario_id',
                value: uid,
              ),
              callback: (payload) {
                final row = payload.newRecord;
                final notificacionId = row['id']?.toString();
                if (notificacionId == null) return;
                if (notificacionId == _ultimaNotificacionId) return;
                _ultimaNotificacionId = notificacionId;

                if (!mounted) return;
                final titulo = row['titulo']?.toString() ?? 'Notificación';
                final mensaje = row['mensaje']?.toString() ?? '';
                _mostrarMensaje('$titulo: $mensaje', esError: false);
              },
            )
            .subscribe();
  }

  Future<void> _detenerEscuchaNotificaciones() async {
    final channel = _notificacionesChannel;
    _notificacionesChannel = null;
    if (channel != null) {
      await channel.unsubscribe();
    }
  }

  @override
  void dispose() {
    _detenerEscuchaNotificaciones();
    super.dispose();
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
    final puedeCrearEmpleados = _perfil == 'dueno' || _perfil == 'supervisor';
    final puedeGestionarMesas =
        _perfil == 'dueno' || _perfil == 'supervisor' || _perfil == 'metre';
    final puedeCrearProductos = _perfil == 'cocinero' || _perfil == 'cantinero';
    final esMetre = _perfil == 'metre';
    final esCliente = _esPerfilCliente(_perfil);
    final esMozo = _perfil == 'mozo';
    final esCocinero = _perfil == 'cocinero';
    final esCantinero = _perfil == 'cantinero';

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Food'),
        actions: [
          TextButton(
            onPressed: _cerrandoSesion ? null : _cerrarSesion,
            child:
                _cerrandoSesion
                    ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: LogoSpinner(size: 18, strokeWidth: 2),
                    )
                    : const Text('Cerrar sesión'),
          ),
        ],
      ),
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
          child: Center(
            child:
                _cargandoPerfil
                    ? const LogoSpinner(size: 90, strokeWidth: 6)
                    : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (esCliente)
                          Expanded(
                            child: _ClienteDashboard(
                              cargandoEstado: _cargandoEstadoMesaCliente,
                              solicitandoMesa: _solicitandoMesa,
                              estadoMesa: _estadoMesaCliente,
                              numeroMesaAsignada:
                                  _mesaAsignada?['numero'] as int?,
                              onSolicitarMesa: _solicitarMesa,
                              onRefrescarEstado: _refrescarEstadoMesaCliente,
                              onEscanearQr: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const MesaQrScannerPage(),
                                  ),
                                );
                              },
                            ),
                          ),
                        if (!esCliente) const SizedBox(height: 20),
                        if (puedeCrearProductos)
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/crear-producto');
                            },
                            child: Text(
                              _perfil == 'cocinero'
                                  ? 'Crear plato'
                                  : 'Crear bebida',
                            ),
                          ),
                        if (puedeCrearProductos) const SizedBox(height: 12),
                        if (puedeCrearProductos)
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                '/carta',
                                arguments:
                                    _perfil == 'cocinero' ? 'plato' : 'bebida',
                              );
                            },
                            child: Text(
                              _perfil == 'cocinero'
                                  ? 'Ver carta de platos'
                                  : 'Ver carta de bebidas',
                            ),
                          ),
                        if (puedeCrearProductos) const SizedBox(height: 12),
                        if (puedeCrearEmpleados)
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/alta-empleado');
                            },
                            child: const Text('Alta de empleados'),
                          ),
                        if (puedeCrearEmpleados) const SizedBox(height: 12),
                        if (puedeCrearEmpleados)
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/crear-mesa');
                            },
                            child: const Text('Crear mesa'),
                          ),
                        if (puedeCrearEmpleados) const SizedBox(height: 12),
                        if (puedeGestionarMesas)
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/ver-editar-mesas');
                            },
                            child: const Text('Ver / editar mesas'),
                          ),
                        if (puedeGestionarMesas) const SizedBox(height: 12),
                        if (puedeCrearEmpleados)
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                '/aprobacion-clientes',
                              );
                            },
                            child: const Text('Gestionar clientes'),
                          ),
                        if (esMetre)
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/asignar-mesa');
                            },
                            child: const Text('Asignar mesa'),
                          ),
                        if (esMetre) const SizedBox(height: 12),
                        if (esMetre)
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/alta-clientes');
                            },
                            child: const Text('Alta cliente'),
                          ),
                        if (esMozo) const SizedBox(height: 12),
                        if (esMozo)
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/pedidos-mozo');
                            },
                            child: const Text('Gestionar pedidos y pagos'),
                          ),
                        if (esMozo) const SizedBox(height: 12),
                        if (esMozo)
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/chat-mozo');
                            },
                            child: const Text('Chat con clientes'),
                          ),
                        if (esCocinero) const SizedBox(height: 12),
                        if (esCocinero)
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/pedidos-cocina');
                            },
                            child: const Text('Pedidos de cocina'),
                          ),
                        if (esCantinero) const SizedBox(height: 12),
                        if (esCantinero)
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/pedidos-bar');
                            },
                            child: const Text('Pedidos de bar'),
                          ),
                        if (!esCliente) const Spacer(),
                      ],
                    ),
          ),
        ),
      ),
    );
  }
}

class _ClienteDashboard extends StatelessWidget {
  const _ClienteDashboard({
    required this.cargandoEstado,
    required this.solicitandoMesa,
    required this.estadoMesa,
    required this.numeroMesaAsignada,
    required this.onSolicitarMesa,
    required this.onRefrescarEstado,
    required this.onEscanearQr,
  });

  final bool cargandoEstado;
  final bool solicitandoMesa;
  final String estadoMesa;
  final int? numeroMesaAsignada;
  final VoidCallback onSolicitarMesa;
  final VoidCallback onRefrescarEstado;
  final VoidCallback onEscanearQr;

  @override
  Widget build(BuildContext context) {
    final puedeSolicitar = estadoMesa == 'sin_solicitud';
    final esperandoMetre = estadoMesa == 'esperando_metre';
    final mesaAsignada = estadoMesa == 'mesa_asignada';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white24),
          ),
          child: Row(
            children: [
              const Icon(Icons.table_restaurant, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child:
                    cargandoEstado
                        ? const Text(
                          'Consultando estado de tu mesa...',
                          style: TextStyle(color: Colors.white),
                        )
                        : Text(
                          mesaAsignada
                              ? 'Mesa asignada: $numeroMesaAsignada'
                              : esperandoMetre
                              ? 'Solicitud enviada. Esperando asignación del metre.'
                              : 'Todavía no solicitaste mesa.',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                Expanded(
                  child: _ClienteActionCard(
                    icon: Icons.how_to_reg,
                    titulo: 'Solicitar mesa',
                    descripcion:
                        'Registra tu solicitud para que el metre pueda asignarte una mesa.',
                    habilitado: puedeSolicitar && !solicitandoMesa,
                    onTap: onSolicitarMesa,
                    loading: solicitandoMesa,
                    color: const Color(0xFF2D6A4F),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: _ClienteActionCard(
                    icon: Icons.sync,
                    titulo: 'Actualizar estado',
                    descripcion:
                        'Consultá si el metre ya te asignó una mesa para continuar.',
                    habilitado: !cargandoEstado,
                    onTap: onRefrescarEstado,
                    loading: cargandoEstado,
                    color: const Color(0xFF0E7490),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: _ClienteActionCard(
                    icon: Icons.qr_code_scanner,
                    titulo: 'Escanear QR de mesa',
                    descripcion:
                        mesaAsignada
                            ? 'Validá el QR de tu mesa para entrar a carta y consultas al mozo.'
                            : 'Se habilita cuando el metre te asigne una mesa.',
                    habilitado: mesaAsignada,
                    onTap: onEscanearQr,
                    loading: false,
                    color: const Color(0xFF7A2021),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ClienteActionCard extends StatelessWidget {
  const _ClienteActionCard({
    required this.icon,
    required this.titulo,
    required this.descripcion,
    required this.habilitado,
    required this.onTap,
    required this.loading,
    required this.color,
  });

  final IconData icon;
  final String titulo;
  final String descripcion;
  final bool habilitado;
  final VoidCallback onTap;
  final bool loading;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: habilitado && !loading ? onTap : null,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          color:
              habilitado
                  ? color.withOpacity(0.88)
                  : Colors.white.withOpacity(0.14),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 30),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      descripcion,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              loading
                  ? const LogoSpinner(size: 22, strokeWidth: 2)
                  : Icon(
                    habilitado ? Icons.chevron_right : Icons.lock_outline,
                    color: Colors.white,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
