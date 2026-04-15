import 'package:all_food/src/features/mesas/data/repositories/mesas_repository.dart';
import 'package:all_food/src/features/mesas/presentation/pages/mesa_qr_scanner_page.dart';
import 'package:flutter/material.dart';
import 'package:all_food/src/features/home/data/repositories/home_repository.dart';
import 'package:all_food/src/shared/errors/app_error_mapper.dart';
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
  bool _cargandoPerfil = true;
  String? _perfil;
  final _homeRepository = HomeRepository();
  final _mesasRepository = MesasRepository();

  List<Map<String, dynamic>> _mesasOcupadas = [];

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
    _cargarMesasOcupadas();
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
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _perfil = null;
        _cargandoPerfil = false;
      });
    }
  }

  Future<void> _cargarMesasOcupadas() async {
    try {
      final mesas = await _mesasRepository.getMesasOcupadas();

      if (!mounted) return;

      setState(() {
        _mesasOcupadas = mesas;
      });
    } catch (_) {
      // opcional: mostrar error
    }
  }

  Future<void> _cerrarSesion() async {
    if (_cerrandoSesion) return;
    setState(() => _cerrandoSesion = true);

    try {
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
    final esCliente =
        _perfil == 'cliente_registrado' || _perfil == 'cliente_anonimo';

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
                      child: CircularProgressIndicator(strokeWidth: 2),
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
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
                        if (_perfil == 'metre') ...[
                          const SizedBox(height: 16),

                          const Text(
                            'Mesas ocupadas',
                            style: TextStyle(color: Colors.white),
                          ),

                          const SizedBox(height: 8),

                          if (_mesasOcupadas.isEmpty)
                            const Text(
                              'No hay mesas ocupadas',
                              style: TextStyle(color: Colors.white70),
                            ),

                          ..._mesasOcupadas.map((mesa) {
                            final cliente = mesa['perfiles'];

                            return ListTile(
                              title: Text(
                                'Mesa ${mesa['numero']}',
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                '${cliente['nombres']} ${cliente['apellidos']}',
                                style: const TextStyle(color: Colors.white70),
                              ),
                            );
                          }),
                        ],
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
                        if (esCliente) const SizedBox(height: 12),
                        if (esCliente)
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const MesaQrScannerPage(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.qr_code_scanner),
                            label: const Text('Escanear QR de mesa'),
                          ),
                      ],
                    ),
          ),
        ),
      ),
    );
  }
}
