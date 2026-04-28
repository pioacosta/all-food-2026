import 'package:all_food/src/features/home/presentation/widgets/staff_welcome_card.dart';
import 'package:all_food/src/features/mesas/data/repositories/mesas_repository.dart';
import 'package:all_food/src/features/mesas/presentation/pages/ingreso_lista_espera_qr_scanner_page.dart';
import 'package:all_food/src/features/mesas/presentation/pages/mesa_qr_scanner_page.dart';
import 'package:all_food/src/features/pedidos/presentation/pages/resultados_encuestas_page.dart';
import 'package:all_food/src/shared/services/notificacion__service.dart';
import 'package:all_food/src/shared/services/session_audio_service.dart';
import 'package:all_food/src/shared/utils/error_feedback.dart';
import 'package:flutter/material.dart';
import 'package:all_food/src/features/home/data/repositories/home_repository.dart';
import 'package:all_food/src/shared/errors/app_error_mapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/widgets/logo_spinner.dart';

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
  String? _nombre;
  String? _apellido;
  String? _email;
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
      final profileData = await _homeRepository.getCurrentUserProfile();
      if (!mounted) return;
      setState(() {
        _perfil = profileData?['perfil'] as String?;
        _nombre = profileData?['nombres'] as String?;
        _apellido = profileData?['apellidos'] as String?;
        _email = profileData?['email'] as String?;
        _cargandoPerfil = false;
      });

      // Inicializar notificaciones cuando ya hay sesión activa
      NotificationService().init();

      _iniciarEscuchaNotificaciones();

      if (_esPerfilCliente(_perfil)) {
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

  Future<void> _escanearQrIngresoYSolicitarMesa() async {
    if (_solicitandoMesa) return;

    setState(() => _solicitandoMesa = true);

    final resultado = await Navigator.of(context).push<IngresoQrResultado>(
      MaterialPageRoute(
        builder: (_) => const IngresoListaEsperaQrScannerPage(),
      ),
    );

    if (!mounted) return;
    setState(() => _solicitandoMesa = false);

    if (resultado != IngresoQrResultado.listaEspera) return;
    try {
      final nombreCliente = [
        _nombre,
        _apellido,
      ].where((s) => s != null && s.isNotEmpty).join(' ');

      await Supabase.instance.client.functions.invoke(
        'notificar-cliente-espera',
        body: {
          'clienteNombre':
              nombreCliente.isNotEmpty ? nombreCliente : 'Un cliente',
        },
      );
    } catch (_) {}
    _mostrarMensaje(
      'Solicitud enviada. Espera a que el metre te asigne una mesa.',
      esError: false,
    );
    await _refrescarEstadoMesaCliente();
  }

  Future<void> _cerrarSesion() async {
    if (_cerrandoSesion) return;
    setState(() => _cerrandoSesion = true);

    try {
      await SessionAudioService.playLogout();
      await NotificationService().resetSessionIdentifier();
      await _detenerEscuchaNotificaciones();
      await Supabase.instance.client.removeAllChannels();

      if (widget.supabaseReady) {
        await _homeRepository.signOut();
      }
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil('/session', (route) => false);
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

                // En cliente, la notificación puede implicar cambios de estado
                // de mesa/pedido, por eso se sincroniza automáticamente.
                if (_esPerfilCliente(_perfil)) {
                  _refrescarEstadoMesaCliente();
                }
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

  List<_DashboardAction> _buildStaffActions({
    required bool puedeCrearProductos,
    required bool puedeCrearEmpleados,
    required bool puedeGestionarMesas,
    required bool esMetre,
    required bool esMozo,
    required bool esCocinero,
    required bool esCantinero,
  }) {
    return [
      if (puedeCrearProductos)
        _DashboardAction(
          icon: Icons.add_circle_outline,
          titulo: _perfil == 'cocinero' ? 'Nuevo plato' : 'Nueva bebida',
          color: const Color(0xFF2D6A4F),
          onTap: () => Navigator.pushNamed(context, '/crear-producto'),
        ),
      if (puedeCrearProductos)
        _DashboardAction(
          icon: Icons.menu_book_rounded,
          titulo: 'Carta',
          color: const Color(0xFF7A2021),
          onTap: () => Navigator.pushNamed(context, '/carta'),
        ),
      if (puedeCrearEmpleados)
        _DashboardAction(
          icon: Icons.badge_outlined,
          titulo: 'Empleados',
          color: const Color(0xFF0E7490),
          onTap: () => Navigator.pushNamed(context, '/alta-empleado'),
        ),
      if (puedeCrearEmpleados)
        _DashboardAction(
          icon: Icons.table_restaurant,
          titulo: 'Nueva mesa',
          color: const Color(0xFF2563EB),
          onTap: () => Navigator.pushNamed(context, '/crear-mesa'),
        ),
      if (puedeGestionarMesas)
        _DashboardAction(
          icon: Icons.edit_road,
          titulo: 'Mesas',
          color: const Color(0xFF7C3AED),
          onTap: () => Navigator.pushNamed(context, '/ver-editar-mesas'),
        ),
      if (puedeCrearEmpleados)
        _DashboardAction(
          icon: Icons.groups_2_outlined,
          titulo: 'Clientes',
          color: const Color(0xFFB45309),
          onTap: () => Navigator.pushNamed(context, '/aprobacion-clientes'),
        ),
      if (esMetre)
        _DashboardAction(
          icon: Icons.assignment_turned_in_outlined,
          titulo: 'Asignar mesa',
          color: const Color(0xFFB91C1C),
          onTap: () => Navigator.pushNamed(context, '/asignar-mesa'),
        ),
      if (esMetre)
        _DashboardAction(
          icon: Icons.person_add_alt_1,
          titulo: 'Alta cliente',
          color: const Color(0xFF0F766E),
          onTap: () => Navigator.pushNamed(context, '/alta-clientes'),
        ),
      if (esMozo)
        _DashboardAction(
          icon: Icons.receipt_long_outlined,
          titulo: 'Gestión',
          color: const Color(0xFF4F46E5),
          onTap: () => Navigator.pushNamed(context, '/pedidos-mozo'),
        ),
      if (esMozo)
        _DashboardAction(
          icon: Icons.help_outline,
          titulo: 'Consultas',
          color: const Color(0xFF6D28D9),
          onTap: () => Navigator.pushNamed(context, '/consultas'),
        ),
      if (esCocinero)
        _DashboardAction(
          icon: Icons.soup_kitchen_outlined,
          titulo: 'Pedidos cocina',
          color: const Color(0xFF15803D),
          onTap: () => Navigator.pushNamed(context, '/pedidos-cocina'),
        ),
      if (esCantinero)
        _DashboardAction(
          icon: Icons.local_bar_outlined,
          titulo: 'Pedidos bar',
          color: const Color(0xFF0369A1),
          onTap: () => Navigator.pushNamed(context, '/pedidos-bar'),
        ),
    ];
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
    final accionesStaff = _buildStaffActions(
      puedeCrearProductos: puedeCrearProductos,
      puedeCrearEmpleados: puedeCrearEmpleados,
      puedeGestionarMesas: puedeGestionarMesas,
      esMetre: esMetre,
      esMozo: esMozo,
      esCocinero: esCocinero,
      esCantinero: esCantinero,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Food'),
        actions: [
          TextButton(
            onPressed: _cerrandoSesion ? null : _cerrarSesion,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFFFE8C2),
              textStyle: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
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
                              onEscanearQrIngreso:
                                  _escanearQrIngresoYSolicitarMesa,
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
                        if (!esCliente)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  StaffWelcomeCard(
                                    nombre: _nombre,
                                    apellido: _apellido,
                                    email: _email,
                                    perfil: _perfil,
                                  ),
                                  const SizedBox(height: 16),
                                  Expanded(
                                    child:
                                        accionesStaff.isEmpty
                                            ? const Center(
                                              child: Text(
                                                'No hay acciones disponibles para este perfil.',
                                                style: TextStyle(
                                                  color: Colors.white70,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            )
                                            : _StaffActionsList(
                                              acciones: accionesStaff,
                                            ),
                                  ),
                                ],
                              ),
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

class _DashboardAction {
  const _DashboardAction({
    required this.icon,
    required this.titulo,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String titulo;
  final Color color;
  final VoidCallback onTap;
}

class _StaffActionsList extends StatelessWidget {
  const _StaffActionsList({required this.acciones});

  final List<_DashboardAction> acciones;

  @override
  Widget build(BuildContext context) {
    // Si hay pocas acciones, ocupamos toda la altura con tarjetas adaptables.
    // Si hay muchas, usamos scroll para preservar legibilidad.
    if (acciones.length <= 6) {
      return Column(
        children: [
          for (var i = 0; i < acciones.length; i++) ...[
            Expanded(
              child: _DashboardActionCard(
                icon: acciones[i].icon,
                titulo: acciones[i].titulo,
                color: acciones[i].color,
                onTap: acciones[i].onTap,
              ),
            ),
            if (i < acciones.length - 1) const SizedBox(height: 12),
          ],
        ],
      );
    }

    return ListView.separated(
      itemCount: acciones.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final accion = acciones[index];
        return _DashboardActionCard(
          icon: accion.icon,
          titulo: accion.titulo,
          color: accion.color,
          onTap: accion.onTap,
        );
      },
    );
  }
}

class _DashboardActionCard extends StatelessWidget {
  const _DashboardActionCard({
    required this.icon,
    required this.titulo,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String titulo;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 30),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  titulo,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                    height: 1.1,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Colors.white),
            ],
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
    required this.onEscanearQrIngreso,
    required this.onRefrescarEstado,
    required this.onEscanearQr,
  });

  final bool cargandoEstado;
  final bool solicitandoMesa;
  final String estadoMesa;
  final int? numeroMesaAsignada;
  final VoidCallback onEscanearQrIngreso;
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
          padding: const EdgeInsets.all(18),
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white24),
          ),
          child: Row(
            children: [
              const Icon(Icons.table_restaurant, color: Colors.white, size: 36),
              const SizedBox(width: 10),
              Expanded(
                child:
                    cargandoEstado
                        ? const Text(
                          'Consultando estado de tu mesa...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                        : Text(
                          mesaAsignada
                              ? 'Mesa asignada: $numeroMesaAsignada'
                              : esperandoMetre
                              ? 'Solicitud enviada. Esperando asignación del metre.'
                              : 'Todavía no solicitaste mesa.',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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
                    icon: Icons.qr_code_scanner,
                    titulo: 'Escanear QR de entrada',
                    descripcion:
                        puedeSolicitar
                            ? 'Escaneá el QR de entrada para anotarte en la lista de espera.'
                            : esperandoMetre
                            ? 'Ya estás en lista de espera. Aguarda asignación del metre.'
                            : 'Ya tenés una mesa asignada, no hace falta escanear nuevamente.',
                    habilitado: puedeSolicitar && !solicitandoMesa,
                    onTap: onEscanearQrIngreso,
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
                const SizedBox(height: 10),
                Expanded(
                  child: _ClienteActionCard(
                    icon: Icons.add_chart_sharp,
                    titulo: 'Ver Encuestas',
                    descripcion: 'Ver resultados de encuestas',
                    habilitado: true,
                    onTap:
                        () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ResultadosEncuestasPage(),
                          ),
                        ),
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
                  ? color.withValues(alpha: 0.88)
                  : Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white24),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 34),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      descripcion,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.25,
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

