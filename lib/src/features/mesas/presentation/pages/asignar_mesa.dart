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

  List<Map<String, dynamic>> _clientes = [];
  List<Map<String, dynamic>> _mesas = [];

  Map<String, dynamic>? _clienteSeleccionado;
  Map<String, dynamic>? _mesaSeleccionada;

  bool _loading = true;
  bool _asignando = false;

  // 0 = eligiendo cliente, 1 = eligiendo mesa
  int _paso = 0;
  int _porPaginaClientes = 0;
  int _porPaginaMesas = 0;

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
        _loading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final altoPagina =
            MediaQuery.of(context).size.height -
            MediaQuery.of(context).padding.top -
            MediaQuery.of(context).padding.bottom -
            220; // altura aproximada del header + botón
        const cardHeight = 76.0;
        const spacing = 8.0;
        final calculado = ((altoPagina) / (cardHeight + spacing)).floor().clamp(
          1,
          5,
        );
        setState(() {
          _porPaginaClientes = calculado;
          _porPaginaMesas = calculado;
        });
      });
    } catch (e) {
      _mostrarMensaje('Error al cargar datos', true);
      setState(() => _loading = false);
    }
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
                            color: Colors.white.withOpacity(0.3),
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
                  child:
                      _paso == 0
                          ? _ListaPaginada(
                            items: _clientes,
                            emptyText: 'No hay clientes disponibles',
                            porPaginaFijo: _porPaginaClientes,
                            itemBuilder: (cliente) {
                              final sel =
                                  _clienteSeleccionado?['id'] == cliente['id'];
                              return _ClienteCard(
                                cliente: cliente,
                                seleccionado: sel,
                                onTap:
                                    () => setState(() {
                                      _clienteSeleccionado = cliente;
                                    }),
                              );
                            },
                          )
                          : _ListaPaginada(
                            items: _mesas,
                            emptyText: 'No hay mesas disponibles',
                            porPaginaFijo: _porPaginaMesas,
                            itemBuilder: (mesa) {
                              final sel =
                                  _mesaSeleccionada?['id'] == mesa['id'];
                              return _MesaCard(
                                mesa: mesa,
                                seleccionado: sel,
                                onTap:
                                    () => setState(
                                      () => _mesaSeleccionada = mesa,
                                    ),
                              );
                            },
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
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              if (_clienteSeleccionado != null)
                                Expanded(
                                  child: _ResumenRow(
                                    icon: Icons.person,
                                    value:
                                        '${_clienteSeleccionado!['nombres']} ${_clienteSeleccionado!['apellidos']}',
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
                      GestureDetector(
                        onTap:
                            _asignando
                                ? null
                                : () {
                                  if (_paso == 0 &&
                                      _clienteSeleccionado != null) {
                                    setState(() => _paso = 1);
                                  } else if (_paso == 1 &&
                                      _clienteSeleccionado != null &&
                                      _mesaSeleccionada != null) {
                                    _asignar();
                                  }
                                },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            color:
                                _botonHabilitado
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
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
                                      _paso == 0
                                          ? 'Siguiente →'
                                          : 'Asignar mesa',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color:
                                            _botonHabilitado
                                                ? const Color(0xFF5B1718)
                                                : Colors.white54,
                                      ),
                                    ),
                          ),
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

// ─── Lista paginada sin scroll ────────────────────────────────────────────────
class _ListaPaginada extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final String emptyText;
  final Widget Function(Map<String, dynamic>) itemBuilder;
  final int? porPaginaFijo;

  const _ListaPaginada({
    required this.items,
    required this.emptyText,
    required this.itemBuilder,
    this.porPaginaFijo,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          emptyText,
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const cardHeight = 76.0;
        const spacing = 8.0;
        final porPagina =
            porPaginaFijo != null && porPaginaFijo! > 0
                ? porPaginaFijo!
                : ((constraints.maxHeight) / (cardHeight + spacing))
                    .floor()
                    .clamp(1, 8);

        final paginas = <List<Map<String, dynamic>>>[];
        for (var i = 0; i < items.length; i += porPagina) {
          paginas.add(items.sublist(i, (i + porPagina).clamp(0, items.length)));
        }

        return Stack(
          children: [
            PageView.builder(
              scrollDirection: Axis.vertical,
              itemCount: paginas.length,
              itemBuilder: (context, pageIndex) {
                final grupo = paginas[pageIndex];
                // Distribuir el espacio disponible entre las cards
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      for (var i = 0; i < grupo.length; i++) ...[
                        Expanded(child: itemBuilder(grupo[i])),
                        if (i < grupo.length - 1)
                          const SizedBox(height: spacing),
                      ],
                    ],
                  ),
                );
              },
            ),
            // Hint de deslizar si hay más de una página
            if (paginas.length > 1)
              Positioned(
                bottom: 8,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.white70,
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Deslizá para ver más',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                seleccionado ? const Color(0xFF5B1718) : Colors.grey.shade200,
            width: seleccionado ? 2 : 1,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Escala el contenido según el alto de la card
            final alto = constraints.maxHeight;
            final avatarRadius = (alto * 0.22).clamp(18.0, 40.0);
            final fontSize = (alto * 0.12).clamp(16.0, 18.0);
            final subFontSize = (alto * 0.09).clamp(14.0, 14.0);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: avatarRadius,
                    backgroundColor:
                        seleccionado
                            ? const Color(0xFF5B1718).withOpacity(0.1)
                            : Colors.grey.shade100,
                    backgroundImage:
                        cliente['foto_url'] != null
                            ? NetworkImage(cliente['foto_url'])
                            : null,
                    child:
                        cliente['foto_url'] == null
                            ? Icon(
                              Icons.person,
                              size: avatarRadius,
                              color:
                                  seleccionado
                                      ? const Color(0xFF5B1718)
                                      : Colors.grey.shade400,
                            )
                            : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${cliente['nombres']} ${cliente['apellidos']}',
                          style: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.w600,
                            color:
                                seleccionado
                                    ? const Color(0xFF5B1718)
                                    : const Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          cliente['correo'] ?? '',
                          style: TextStyle(
                            fontSize: subFontSize,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        if (cliente['dni'] != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'DNI: ${cliente['dni']}',
                            style: TextStyle(
                              fontSize: subFontSize,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (seleccionado)
                    Icon(
                      Icons.check_circle,
                      color: const Color(0xFF5B1718),
                      size: (avatarRadius * 0.8).clamp(16.0, 28.0),
                    ),
                ],
              ),
            );
          },
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: seleccionado ? const Color(0xFF5B1718) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                seleccionado ? const Color(0xFF5B1718) : Colors.grey.shade200,
            width: seleccionado ? 2 : 1,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final alto = constraints.maxHeight;
            final iconSize = (alto * 0.28).clamp(24.0, 52.0);
            final fontSize = (alto * 0.13).clamp(13.0, 22.0);
            final subFontSize = (alto * 0.10).clamp(11.0, 16.0);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: iconSize * 1.6,
                    height: iconSize * 1.6,
                    decoration: BoxDecoration(
                      color:
                          seleccionado
                              ? Colors.white.withOpacity(0.15)
                              : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.table_restaurant,
                      size: iconSize,
                      color: seleccionado ? Colors.white : Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mesa ${mesa['numero']}',
                          style: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.w700,
                            color:
                                seleccionado
                                    ? Colors.white
                                    : const Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${mesa['cantidad_lugares']} lugares',
                          style: TextStyle(
                            fontSize: subFontSize,
                            color:
                                seleccionado
                                    ? Colors.white70
                                    : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (seleccionado)
                    Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: (iconSize * 0.7).clamp(16.0, 28.0),
                    ),
                ],
              ),
            );
          },
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
                      ? Colors.white.withOpacity(0.3)
                      : Colors.white.withOpacity(0.1),
              border: Border.all(
                color:
                    activo || completo
                        ? Colors.white
                        : Colors.white.withOpacity(0.3),
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
