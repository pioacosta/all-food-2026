import 'package:all_food/src/features/staff/data/repositories/staff_repository.dart';
import 'package:all_food/src/shared/widgets/logo_spinner.dart';
import 'package:flutter/material.dart';

class ClientesPendientesPage extends StatefulWidget {
  const ClientesPendientesPage({required this.supabaseReady, super.key});

  final bool supabaseReady;

  @override
  State<ClientesPendientesPage> createState() => _ClientesPendientesPageState();
}

class _ClientesPendientesPageState extends State<ClientesPendientesPage> {
  final _staffRepository = StaffRepository();

  bool _cargando = true;
  bool _puedeGestionarClientes = false;
  List<Map<String, dynamic>> _clientes = [];

  @override
  void initState() {
    super.initState();
    _cargarTodo();
  }

  Future<void> _cargarTodo() async {
    if (!widget.supabaseReady) {
      setState(() => _cargando = false);
      return;
    }

    try {
      final autorizado = await _staffRepository.canCurrentUserCreateEmployees();
      if (!mounted) return;

      if (!autorizado) {
        setState(() {
          _cargando = false;
          _puedeGestionarClientes = false;
        });
        return;
      }

      final clientes = await _staffRepository.pendingClients();
      if (!mounted) return;

      setState(() {
        _cargando = false;
        _puedeGestionarClientes = true;
        _clientes = clientes;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _cargando = false);
    }
  }

  void _recargar() async {
    setState(() => _cargando = true);
    final clientes = await _staffRepository.pendingClients();
    if (!mounted) return;
    setState(() {
      _cargando = false;
      _clientes = clientes;
    });
  }

  void _mostrarMensaje(String mensaje, {required bool esError}) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            mensaje,
            maxLines: esError ? 4 : 2,
            overflow: TextOverflow.ellipsis,
          ),
          duration: Duration(seconds: esError ? 8 : 4),
          backgroundColor:
              esError ? const Color(0xFF992E2E) : const Color(0xFF2D6A4F),
        ),
      );
  }

  Future<void> _aprobar(Map<String, dynamic> cliente) async {
    try {
      await _staffRepository.approveClient(cliente['id']);
      _mostrarMensaje(
        'Cliente ${cliente['nombres']} aprobado correctamente.',
        esError: false,
      );
      _recargar();
    } catch (e) {
      _mostrarMensaje('Error al aprobar: $e', esError: true);
    }
  }

  Future<void> _rechazar(Map<String, dynamic> cliente) async {
    try {
      await _staffRepository.rejectClient(cliente['id']);
      _mostrarMensaje(
        'Cliente ${cliente['nombres']} rechazado.',
        esError: true,
      );
      _recargar();
    } catch (e) {
      _mostrarMensaje('Error al rechazar: $e', esError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(
        body: Center(child: LogoSpinner(size: 88, strokeWidth: 6)),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Clientes pendientes')),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF5B1718), Color(0xFF7A2021)],
          ),
        ),
        child: SafeArea(
          child:
              !_puedeGestionarClientes
                  ? const Center(
                    child: Text(
                      'No tenés permisos para gestionar clientes.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                  : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
                        child: Column(
                          children: [
                            const Text(
                              'Clientes pendientes',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'ArchivoBlack',
                                fontSize: 32,
                                color: Colors.white,
                                letterSpacing: -1.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Revisá cada solicitud y aprobá o rechazá el acceso del cliente a la app',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  size: 15,
                                  color: Colors.white54,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${_clientes.length} pendiente${_clientes.length != 1 ? 's' : ''}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.white54,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child:
                            _clientes.isEmpty
                                ? const Center(
                                  child: Text(
                                    'No hay pendientes',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                )
                                : ListView.builder(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  itemCount: _clientes.length,
                                  itemBuilder: (context, index) {
                                    final cliente = _clientes[index];
                                    final nombre =
                                        '${cliente['nombres']} ${cliente['apellidos']}';
                                    return Card(
                                      elevation: 0,
                                      color: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(
                                          color: Colors.grey.shade200,
                                        ),
                                      ),
                                      margin: const EdgeInsets.only(bottom: 10),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 14,
                                        ),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 30,
                                              backgroundColor:
                                                  Colors.grey.shade200,
                                              backgroundImage:
                                                  cliente['foto_url'] != null
                                                      ? NetworkImage(
                                                        cliente['foto_url'],
                                                      )
                                                      : null,
                                              child:
                                                  cliente['foto_url'] == null
                                                      ? const Icon(
                                                        Icons.person,
                                                        color: Colors.grey,
                                                      )
                                                      : null,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    nombre,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  Text(
                                                    cliente['correo'] ?? '',
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                  if (cliente['dni'] != null)
                                                    Text(
                                                      'DNI: ${cliente['dni']}',
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            Column(
                                              children: [
                                                _ActionButton(
                                                  color: Colors.green,
                                                  icon: Icons.check,
                                                  onTap:
                                                      () => _aprobar(cliente),
                                                ),
                                                const SizedBox(height: 6),
                                                _ActionButton(
                                                  color: Colors.red,
                                                  icon: Icons.close,
                                                  onTap:
                                                      () => _rechazar(cliente),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
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

class _ActionButton extends StatelessWidget {
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionButton({
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
      ),
    );
  }
}
