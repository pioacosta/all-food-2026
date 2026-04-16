import 'package:all_food/src/features/clientes/data/repository/cliente_repository.dart';
import 'package:all_food/src/shared/widgets/logo_spinner.dart';
import 'package:flutter/material.dart';

class ClientesPendientesPage extends StatefulWidget {
  const ClientesPendientesPage({required this.supabaseReady, super.key});

  final bool supabaseReady;

  @override
  State<ClientesPendientesPage> createState() => _ClientesPendientesPageState();
}

class _ClientesPendientesPageState extends State<ClientesPendientesPage> {
  final _clienteRepository = ClientesRepository();

  bool _cargando = true;
  bool _puedeGestionarClientes = false;
  List<Map<String, dynamic>> _clientes = [];
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _cargarTodo();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _cargarTodo() async {
    if (!widget.supabaseReady) {
      setState(() => _cargando = false);
      return;
    }
    try {
      final autorizado =
          await _clienteRepository.canManageClients();
      if (!mounted) return;
      if (!autorizado) {
        setState(() {
          _cargando = false;
          _puedeGestionarClientes = false;
        });
        return;
      }
      final clientes = await _clienteRepository.getPendingClients();
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

  Future<void> _recargar() async {
    final clientes = await _clienteRepository.getPendingClients();
    if (!mounted) return;
    setState(() {
      _clientes = clientes;
      _currentIndex = 0;
    });
    if (_pageController.hasClients) {
      _pageController.jumpToPage(0);
    }
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
      await _clienteRepository.approveClient(cliente['id']);
      _mostrarMensaje(
        'Cliente ${cliente['nombres']} aprobado correctamente.',
        esError: false,
      );
      await _recargar();
    } catch (e) {
      _mostrarMensaje('Error al aprobar: $e', esError: true);
    }
  }

  Future<void> _rechazar(Map<String, dynamic> cliente) async {
    try {
      await _clienteRepository.rejectClient(cliente['id']);
      _mostrarMensaje(
        'Cliente ${cliente['nombres']} rechazado.',
        esError: true,
      );
      await _recargar();
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
          child: !_puedeGestionarClientes
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No tenés permisos para gestionar clientes.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Header ─────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 20, 18, 8),
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
                          Text(
                            _clientes.isEmpty
                                ? 'No hay solicitudes pendientes'
                                : 'Deslizá horizontal para aprobar o rechazar',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 20),
                          ),
                          const SizedBox(height: 8),
                          if (_clientes.isNotEmpty)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${_clientes.length} clientes pendiente${_clientes.length != 1 ? 's' : ''}',
                                  style: const TextStyle(
                                      fontSize: 18, color: Colors.white54),
                                ),
                              ],
                            ),
                            
                        ],
                      ),
                    ),

                    // ── Lista vertical ─────────────────────────────────
                    Expanded(
                      child: _clientes.isEmpty
                          ? const Center(
                              child: Text(
                                'No hay pendientes',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 16),
                              ),
                            )
                          : PageView.builder(
                              controller: _pageController,
                              scrollDirection: Axis.vertical, // 👈 clave
                              itemCount: _clientes.length,
                              onPageChanged: (i) =>
                                  setState(() => _currentIndex = i),
                              itemBuilder: (context, index) {
                                final cliente = _clientes[index];
                                return Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      16, 8, 16, 16),
                                  child: _ClienteSwipeCard(
                                    key: ValueKey(cliente['id'] ?? index),
                                    cliente: cliente,
                                    onAprobar: () => _aprobar(cliente),
                                    onRechazar: () => _rechazar(cliente),
                                  ),
                                );
                              },
                            ),
                    ),

                    // ── Indicador: cliente X de N ──────────────────────
                    if (_clientes.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          '${_currentIndex + 1} de ${_clientes.length}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 13),
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ─── Card con swipe ───────────────────────────────────────────────
class _ClienteSwipeCard extends StatefulWidget {
  final Map<String, dynamic> cliente;
  final VoidCallback onAprobar;
  final VoidCallback onRechazar;

  const _ClienteSwipeCard({
    super.key,
    required this.cliente,
    required this.onAprobar,
    required this.onRechazar,
  });

  @override
  State<_ClienteSwipeCard> createState() => _ClienteSwipeCardState();
}

class _ClienteSwipeCardState extends State<_ClienteSwipeCard>
    with SingleTickerProviderStateMixin {
  double _dragX = 0;
  bool _dismissed = false;
  late AnimationController _snapController;
  late Animation<double> _snapAnim;

  @override
  void initState() {
    super.initState();
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _snapController.dispose();
    super.dispose();
  }

  void _snapBack() {
    _snapAnim = Tween<double>(begin: _dragX, end: 0).animate(
      CurvedAnimation(parent: _snapController, curve: Curves.elasticOut),
    )..addListener(() => setState(() => _dragX = _snapAnim.value));
    _snapController.forward(from: 0);
  }

  void _onDragEnd(double velocity) {
    final threshold = MediaQuery.of(context).size.width * 0.35;
    if (_dragX > threshold || velocity > 600) {
      setState(() => _dismissed = true);
      Future.delayed(const Duration(milliseconds: 200), widget.onAprobar);
    } else if (_dragX < -threshold || velocity < -600) {
      setState(() => _dismissed = true);
      Future.delayed(const Duration(milliseconds: 200), widget.onRechazar);
    } else {
      _snapBack();
    }
  }

  @override
  Widget build(BuildContext context) {
    final nombre =
        '${widget.cliente['nombres']} ${widget.cliente['apellidos']}';
    final angle = (_dragX / 800).clamp(-0.3, 0.3);
    final acceptOpacity = (_dragX / 150).clamp(0.0, 1.0);
    final rejectOpacity = (-_dragX / 150).clamp(0.0, 1.0);

    return GestureDetector(
      onHorizontalDragUpdate: (d) =>
          setState(() => _dragX += d.delta.dx),
      onHorizontalDragEnd: (d) =>
          _onDragEnd(d.velocity.pixelsPerSecond.dx),
      child: AnimatedOpacity(
        opacity: _dismissed ? 0 : 1,
        duration: const Duration(milliseconds: 200),
        child: Transform(
          transform: Matrix4.identity()
            ..translate(_dragX, 0)
            ..rotateZ(angle),
          alignment: Alignment.bottomCenter,
          child: Stack(
            children: [
              // ── Card principal ─────────────────────────────────────
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 80,
                            backgroundColor: Colors.grey.shade100,
                            backgroundImage:
                                widget.cliente['foto_url'] != null
                                    ? NetworkImage(
                                        widget.cliente['foto_url'])
                                    : null,
                            child: widget.cliente['foto_url'] == null
                                ? Icon(Icons.person,
                                    size: 52,
                                    color: Colors.grey.shade400)
                                : null,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            nombre,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.cliente['correo'] ?? '',
                            style: TextStyle(
                                fontSize: 20,
                                color: Colors.grey.shade500),
                          ),
                          if (widget.cliente['dni'] != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'DNI: ${widget.cliente['dni']}',
                                style: TextStyle(
                                    fontSize: 17,
                                    color: Colors.grey.shade600),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // ── Hints de swipe ───────────────────────────────
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Row(children: [
                            Icon(Icons.arrow_back_ios,
                                size: 13,
                                color: Colors.grey.shade400),
                            Text('Rechazar',
                                style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.grey.shade400)),
                          ]),
                          Row(children: [
                            Text('Aprobar',
                                style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.grey.shade400)),
                            Icon(Icons.arrow_forward_ios,
                                size: 13,
                                color: Colors.grey.shade400),
                          ]),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Botones grandes ──────────────────────────────
                    Padding(
                      padding:
                          const EdgeInsets.fromLTRB(32, 0, 32, 28),
                      child: Row(
                        children: [
                          Expanded(
                            child: _BigActionButton(
                              color: const Color(0xFFE24B4A),
                              backgroundColor:
                                  const Color(0xFFFCEBEB),
                              icon: Icons.close_rounded,
                              label: 'Rechazar',
                              onTap: widget.onRechazar,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _BigActionButton(
                              color: const Color(0xFF639922),
                              backgroundColor:
                                  const Color(0xFFEAF3DE),
                              icon: Icons.check_rounded,
                              label: 'Aprobar',
                              onTap: widget.onAprobar,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Overlay APROBADO ───────────────────────────────────
              if (acceptOpacity > 0.05)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: acceptOpacity,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF639922)
                              .withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                              color: const Color(0xFF639922),
                              width: 3),
                        ),
                        alignment: Alignment.topLeft,
                        padding: const EdgeInsets.all(20),
                        child: const Text(
                          'APROBADO',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF3B6D11),
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // ── Overlay RECHAZADO ──────────────────────────────────
              if (rejectOpacity > 0.05)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: rejectOpacity,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFE24B4A)
                              .withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                              color: const Color(0xFFE24B4A),
                              width: 3),
                        ),
                        alignment: Alignment.topRight,
                        padding: const EdgeInsets.all(20),
                        child: const Text(
                          'RECHAZADO',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFA32D2D),
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Botón grande ─────────────────────────────────────────────────────────────
class _BigActionButton extends StatelessWidget {
  final Color color;
  final Color backgroundColor;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _BigActionButton({
    required this.color,
    required this.backgroundColor,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}