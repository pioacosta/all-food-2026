import 'package:all_food/src/features/mesas/data/repositories/mesas_repository.dart';
import 'package:all_food/src/shared/widgets/logo_spinner.dart';
import 'package:flutter/material.dart';

class AsignarMesaPage extends StatefulWidget {
  const AsignarMesaPage({required this.supabaseReady, super.key});

  final bool supabaseReady;

  @override
  State<AsignarMesaPage> createState() => _AsignarMesaPageState();
}

class _AsignarMesaPageState extends State<AsignarMesaPage> {
  final _repo = MesasRepository();
  static const int _itemsPorPagina = 4;

  List<Map<String, dynamic>> _clientes = [];
  List<Map<String, dynamic>> _mesas = [];

  Map<String, dynamic>? _clienteSeleccionado;
  Map<String, dynamic>? _mesaSeleccionada;

  bool _loading = true;
  bool _asignando = false;

  // 0 = eligiendo cliente, 1 = eligiendo mesa
  int _paso = 0;
  int _paginaClientes = 0;
  int _paginaMesas = 0;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      final clientes = await _repo.getClientesSinMesa();
      final mesas = await _repo.getMesasDisponibles();
      setState(() {
        _clientes = clientes;
        _mesas = mesas;
        _normalizarPaginas();
        _loading = false;
      });
    } catch (e) {
      _mostrarMensaje('Error al cargar datos', true);
      setState(() => _loading = false);
    }
  }

  int get _totalPaginasClientes {
    if (_clientes.isEmpty) return 1;
    return (_clientes.length / _itemsPorPagina).ceil();
  }

  int get _totalPaginasMesas {
    if (_mesas.isEmpty) return 1;
    return (_mesas.length / _itemsPorPagina).ceil();
  }

  List<Map<String, dynamic>> get _clientesPagina {
    final inicio = _paginaClientes * _itemsPorPagina;
    final fin = (inicio + _itemsPorPagina).clamp(0, _clientes.length);
    if (inicio >= _clientes.length) return const [];
    return _clientes.sublist(inicio, fin);
  }

  List<Map<String, dynamic>> get _mesasPagina {
    final inicio = _paginaMesas * _itemsPorPagina;
    final fin = (inicio + _itemsPorPagina).clamp(0, _mesas.length);
    if (inicio >= _mesas.length) return const [];
    return _mesas.sublist(inicio, fin);
  }

  void _normalizarPaginas() {
    if (_paginaClientes > _totalPaginasClientes - 1) {
      _paginaClientes = (_totalPaginasClientes - 1).clamp(0, 999999);
    }
    if (_paginaMesas > _totalPaginasMesas - 1) {
      _paginaMesas = (_totalPaginasMesas - 1).clamp(0, 999999);
    }
  }

  void _irPaginaAnterior() {
    setState(() {
      if (_paso == 0 && _paginaClientes > 0) {
        _paginaClientes -= 1;
      } else if (_paso == 1 && _paginaMesas > 0) {
        _paginaMesas -= 1;
      }
    });
  }

  void _irPaginaSiguiente() {
    setState(() {
      if (_paso == 0 && _paginaClientes < _totalPaginasClientes - 1) {
        _paginaClientes += 1;
      } else if (_paso == 1 && _paginaMesas < _totalPaginasMesas - 1) {
        _paginaMesas += 1;
      }
    });
  }

  Future<void> _asignar() async {
    if (_clienteSeleccionado == null || _mesaSeleccionada == null) {
      _mostrarMensaje('Seleccioná un cliente y una mesa', true);
      return;
    }
    setState(() => _asignando = true);
    try {
      await _repo.asignarMesa(
        cliente: _clienteSeleccionado!,
        mesa: _mesaSeleccionada!,
      );
      _mostrarMensaje(
        'Mesa ${_mesaSeleccionada!['numero']} asignada a '
        '${_clienteSeleccionado!['nombres']} correctamente.',
        false,
      );
      await _cargarDatos();
      setState(() {
        _clienteSeleccionado = null;
        _mesaSeleccionada = null;
        _paso = 0;
      });
    } catch (e) {
      _mostrarMensaje(e.toString().replaceFirst('Exception: ', ''), true);
    } finally {
      setState(() => _asignando = false);
    }
  }

  void _mostrarMensaje(String msg, bool error) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(msg, maxLines: 3, overflow: TextOverflow.ellipsis),
          duration: Duration(seconds: error ? 6 : 4),
          backgroundColor:
              error ? const Color(0xFF992E2E) : const Color(0xFF2D6A4F),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: LogoSpinner(size: 88, strokeWidth: 6)),
      );
    }

    return PopScope(
      canPop: _paso == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _paso == 1) {
          setState(() => _paso = 0);
        }
      },

      child: Scaffold(
        appBar: AppBar(title: const Text('Asignar mesa')),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header ────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 12),
                  child: Column(
                    children: [
                      const Text(
                        'Asignar mesa',
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
                        _paso == 0
                            ? 'Elegí el cliente a sentar'
                            : 'Elegí la mesa para ${_clienteSeleccionado!['nombres']}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── Indicador de pasos ───────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: _PasoIndicador(
                              numero: '1',
                              label: 'Cliente',
                              activo: _paso == 0,
                              completo: _clienteSeleccionado != null,
                              onTap: () => setState(() => _paso = 0),
                            ),
                          ),
                          Container(
                            width: 32,
                            height: 2,
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                          Expanded(
                            child: _PasoIndicador(
                              numero: '2',
                              label: 'Mesa',
                              activo: _paso == 1,
                              completo: _mesaSeleccionada != null,
                              onTap:
                                  _clienteSeleccionado != null
                                      ? () => setState(() => _paso = 1)
                                      : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Contenido paginado ────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    child: Column(
                      children: [
                        Expanded(
                          child:
                              _paso == 0
                                  ? (_clientes.isEmpty
                                      ? const Center(
                                        child: Text(
                                          'No hay clientes disponibles',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 16,
                                          ),
                                        ),
                                      )
                                      : ListView.separated(
                                        itemCount: _clientesPagina.length,
                                        separatorBuilder:
                                            (_, __) => const SizedBox(height: 8),
                                        itemBuilder: (context, index) {
                                          final cliente = _clientesPagina[index];
                                          final sel =
                                              _clienteSeleccionado?['id'] ==
                                              cliente['id'];
                                          return _ClienteCard(
                                            cliente: cliente,
                                            seleccionado: sel,
                                            onTap:
                                                () => setState(() {
                                                  _clienteSeleccionado =
                                                      cliente;
                                                }),
                                          );
                                        },
                                      ))
                                  : (_mesas.isEmpty
                                      ? const Center(
                                        child: Text(
                                          'No hay mesas disponibles',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 16,
                                          ),
                                        ),
                                      )
                                      : ListView.separated(
                                        itemCount: _mesasPagina.length,
                                        separatorBuilder:
                                            (_, __) => const SizedBox(height: 8),
                                        itemBuilder: (context, index) {
                                          final mesa = _mesasPagina[index];
                                          final sel =
                                              _mesaSeleccionada?['id'] ==
                                              mesa['id'];
                                          return _MesaCard(
                                            mesa: mesa,
                                            seleccionado: sel,
                                            onTap:
                                                () => setState(
                                                  () => _mesaSeleccionada = mesa,
                                                ),
                                          );
                                        },
                                      )),
                        ),
                        const SizedBox(height: 10),
                        _PaginacionLista(
                          paginaActual:
                              _paso == 0 ? _paginaClientes : _paginaMesas,
                          totalPaginas:
                              _paso == 0
                                  ? _totalPaginasClientes
                                  : _totalPaginasMesas,
                          onAnterior: _irPaginaAnterior,
                          onSiguiente: _irPaginaSiguiente,
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Botón / resumen ───────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Column(
                    children: [
                      // Resumen
                      if (_clienteSeleccionado != null ||
                          _mesaSeleccionada != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              if (_clienteSeleccionado != null)
                                Expanded(
                                  child: _ResumenRow(
                                    icon: Icons.person,
                                    value:
                                        _clienteSeleccionado!['perfil'] ==
                                                'cliente_anonimo'
                                            ? '${_clienteSeleccionado!['nombres']}'
                                            : '${_clienteSeleccionado!['nombres']} ${_clienteSeleccionado!['apellidos']}',
                                  ),
                                ),
                              if (_clienteSeleccionado != null &&
                                  _mesaSeleccionada != null)
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                  child: Icon(
                                    Icons.arrow_forward,
                                    color: Colors.white54,
                                    size: 16,
                                  ),
                                ),
                              if (_mesaSeleccionada != null)
                                Expanded(
                                  child: _ResumenRow(
                                    icon: Icons.table_restaurant,
                                    value:
                                        'Mesa ${_mesaSeleccionada!['numero']}',
                                  ),
                                ),
                            ],
                          ),
                        ),

                      // Botón
                      FilledButton(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF5B1718),
                          disabledBackgroundColor: Colors.white24,
                          disabledForegroundColor: Colors.white54,
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        onPressed:
                            !_botonHabilitado || _asignando
                                ? null
                                : () {
                                  if (_paso == 0 &&
                                      _clienteSeleccionado != null) {
                                    setState(() {
                                      _paso = 1;
                                      _paginaMesas = 0;
                                    });
                                  } else if (_paso == 1 &&
                                      _clienteSeleccionado != null &&
                                      _mesaSeleccionada != null) {
                                    _asignar();
                                  }
                                },
                        child:
                            _asignando
                                ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Color(0xFF5B1718),
                                  ),
                                )
                                : Text(
                                  _paso == 0 ? 'Siguiente →' : 'Asignar mesa',
                                ),
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

  bool get _botonHabilitado {
    if (_paso == 0) return _clienteSeleccionado != null;
    return _clienteSeleccionado != null && _mesaSeleccionada != null;
  }
}

class _PaginacionLista extends StatelessWidget {
  const _PaginacionLista({
    required this.paginaActual,
    required this.totalPaginas,
    required this.onAnterior,
    required this.onSiguiente,
  });

  final int paginaActual;
  final int totalPaginas;
  final VoidCallback onAnterior;
  final VoidCallback onSiguiente;

  @override
  Widget build(BuildContext context) {
    final puedeAnterior = paginaActual > 0;
    final puedeSiguiente = paginaActual < totalPaginas - 1;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: puedeAnterior ? onAnterior : null,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(42),
              foregroundColor: const Color(0xFF4A0E10),
              backgroundColor: Colors.white,
              disabledForegroundColor: Colors.white54,
              disabledBackgroundColor: const Color(0xFF7A2021),
              side: const BorderSide(color: Colors.white, width: 1.4),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
            icon: const Icon(Icons.chevron_left),
            label: const Text('Anterior'),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Página ${paginaActual + 1} / $totalPaginas',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: puedeSiguiente ? onSiguiente : null,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(42),
              foregroundColor: const Color(0xFF4A0E10),
              backgroundColor: Colors.white,
              disabledForegroundColor: Colors.white54,
              disabledBackgroundColor: const Color(0xFF7A2021),
              side: const BorderSide(color: Colors.white, width: 1.4),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
            icon: const Icon(Icons.chevron_right),
            label: const Text('Siguiente'),
          ),
        ),
      ],
    );
  }
}

// ─── Card cliente ─────────────────────────────────────────────────────────────
class _ClienteCard extends StatelessWidget {
  final Map<String, dynamic> cliente;
  final bool seleccionado;
  final VoidCallback onTap;

  const _ClienteCard({
    required this.cliente,
    required this.seleccionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool esAnonimo = cliente['perfil'] == 'cliente_anonimo';
    final String etiquetaTexto = esAnonimo ? 'Anónimo' : 'Registrado';
    final nombreCompleto =
        esAnonimo
            ? '${cliente['nombres']}'
            : '${cliente['nombres']} ${cliente['apellidos']}';

    return Card(
      margin: EdgeInsets.zero,
      color: seleccionado ? const Color(0xFF8D2628) : const Color(0xFFA02C2C),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: seleccionado ? const Color(0xFFFFE2A8) : const Color(0xFFFFC9C9),
          width: seleccionado ? 1.4 : 0.6,
        ),
      ),
      elevation: 2,
      child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: Colors.white12,
              backgroundImage:
                  cliente['foto_url'] != null
                      ? NetworkImage(cliente['foto_url'])
                      : null,
              child:
                  cliente['foto_url'] == null
                      ? const Icon(Icons.person, color: Colors.white70)
                      : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nombreCompleto,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    esAnonimo ? 'Cliente anónimo' : (cliente['correo'] ?? ''),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFFFFDDDD), fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFFFB9B9)),
              ),
              child: Text(
                etiquetaTexto,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (seleccionado) ...[
              const SizedBox(width: 8),
              const Icon(Icons.check_circle, color: Color(0xFFFFE2A8)),
            ],
          ],
        ),
      ),
    );
  }
}

// CARD mesa
class _MesaCard extends StatelessWidget {
  final Map<String, dynamic> mesa;
  final bool seleccionado;
  final VoidCallback onTap;

  const _MesaCard({
    required this.mesa,
    required this.seleccionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: seleccionado ? const Color(0xFF8D2628) : const Color(0xFFA02C2C),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: seleccionado ? const Color(0xFFFFE2A8) : const Color(0xFFFFC9C9),
          width: seleccionado ? 1.4 : 0.6,
        ),
      ),
      elevation: 2,
      child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.table_restaurant,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mesa ${mesa['numero']}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${mesa['cantidad_lugares']} lugares',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFFFFDDDD), fontSize: 13),
                  ),
                ],
              ),
            ),
            if (seleccionado)
              const Icon(Icons.check_circle, color: Color(0xFFFFE2A8)),
          ],
        ),
      ),
    );
  }
}

// ─── Widgets auxiliares ───────────────────────────────────────────────────────
class _PasoIndicador extends StatelessWidget {
  final String numero;
  final String label;
  final bool activo;
  final bool completo;
  final VoidCallback? onTap;

  const _PasoIndicador({
    required this.numero,
    required this.label,
    required this.activo,
    required this.completo,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  completo
                      ? Colors.white
                      : activo
                      ? Colors.white.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.1),
              border: Border.all(
                color:
                    activo || completo
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Center(
              child:
                  completo
                      ? const Icon(
                        Icons.check,
                        color: Color(0xFF5B1718),
                        size: 18,
                      )
                      : Text(
                        numero,
                        style: TextStyle(
                          color: activo ? Colors.white : Colors.white54,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: activo ? Colors.white : Colors.white54,
              fontSize: 12,
              fontWeight: activo ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResumenRow extends StatelessWidget {
  final IconData icon;
  final String value;

  const _ResumenRow({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.white70),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
