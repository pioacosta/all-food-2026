import 'package:all_food/src/features/carta/data/repositories/carta_repository.dart';
import 'package:all_food/src/features/carta/data/models/producto_model.dart';
import 'package:all_food/src/features/carta/presentation/pages/producto_detalle_page.dart';
import 'package:all_food/src/features/pedidos/data/repositories/pedidos_repository.dart';
import 'package:all_food/src/shared/errors/app_error_mapper.dart';
import 'package:all_food/src/shared/widgets/logo_spinner.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────────────────────
//  CartaClientePage
//  Recibe [tipo] ('plato' | 'bebida') igual que CartaPage,
//  de modo que el flujo puede instanciarla para cada sección.
// ─────────────────────────────────────────────────────────────
class CartaClientePage extends StatefulWidget {
  const CartaClientePage({
    this.initialCategoria,
    this.mesaId,
    this.numeroMesa,
    super.key,
  });

  final String? initialCategoria;
  final String? mesaId;
  final int? numeroMesa;

  @override
  State<CartaClientePage> createState() => _CartaClientePageState();
}

class _CartaClientePageState extends State<CartaClientePage> {
  final _repository = CartaRepository();
  final _pedidosRepository = PedidosRepository();
  final _searchController = TextEditingController();
  // En cliente usamos 3 ítems por página para evitar overflow en pantallas
  // chicas al combinar filtros + resumen + paginación.
  static const int _itemsPorPagina = 3;
  String _categoria = 'todos';
  int _paginaActual = 0;

  List<ProductoModel> _productos = [];
  bool _cargando = true;
  bool _agregando = false;
  String? _error;
  Map<String, dynamic>? _resumenPedido;

  int get _totalPaginas {
    if (_productos.isEmpty) return 1;
    return (_productos.length / _itemsPorPagina).ceil();
  }

  List<ProductoModel> get _productosPagina {
    final inicio = _paginaActual * _itemsPorPagina;
    final fin = (inicio + _itemsPorPagina).clamp(0, _productos.length);
    if (inicio >= _productos.length) return const [];
    return _productos.sublist(inicio, fin);
  }

  void _normalizarPagina() {
    final ultima = _totalPaginas - 1;
    if (_paginaActual > ultima) {
      _paginaActual = ultima;
    }
    if (_paginaActual < 0) {
      _paginaActual = 0;
    }
  }

  @override
  void initState() {
    super.initState();
    final initial = widget.initialCategoria;
    if (initial == 'plato' || initial == 'bebida') {
      _categoria = initial!;
    }
    _cargar();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargar({String? nombre, bool mostrarSpinner = true}) async {
    if (mostrarSpinner) {
      setState(() {
        _cargando = true;
        _error = null;
      });
    } else {
      setState(() {
        _error = null;
      });
    }

    try {
      final tipo = _categoria == 'todos' ? null : _categoria;
      final data = await _repository.getProductos(tipo: tipo, nombre: nombre);

      if (!mounted) return;
      setState(() {
        _productos = data.map(ProductoModel.fromMap).toList();
        _paginaActual = 0;
        _normalizarPagina();
        _cargando = false;
      });

      if (widget.mesaId != null) {
        await _cargarResumenPedido();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = AppErrorMapper.toUserMessage(
          e,
          fallbackMessage: 'Error al cargar los productos.',
        );
        _cargando = false;
      });
    }
  }

  Future<void> _cargarResumenPedido() async {
    final mesaId = widget.mesaId;
    if (mesaId == null) return;

    final detalle = await _pedidosRepository.getDetallePedido(mesaId);
    final pedido = detalle['pedido'] as Map<String, dynamic>?;

    if (!mounted) return;
    setState(() {
      if (pedido == null) {
        _resumenPedido = null;
      } else {
        _resumenPedido = {
          'estado': pedido['estado'],
          'subtotal': pedido['subtotal'],
          'tiempoTotalMin': detalle['tiempoTotalMin'],
        };
      }
    });
  }

  void _onBuscar(String valor) {
    _cargar(nombre: valor.isEmpty ? null : valor);
  }

  void _onCambiarCategoria(String categoria) {
    if (_categoria == categoria) return;
    setState(() {
      _categoria = categoria;
      _paginaActual = 0;
    });
    final nombre = _searchController.text.trim();
    _cargar(nombre: nombre.isEmpty ? null : nombre, mostrarSpinner: false);
  }

  void _irPaginaAnterior() {
    if (_paginaActual == 0) return;
    setState(() {
      _paginaActual -= 1;
    });
  }

  void _irPaginaSiguiente() {
    if (_paginaActual >= _totalPaginas - 1) return;
    setState(() {
      _paginaActual += 1;
    });
  }

  Future<void> _onAgregarAlPedido(
    ProductoModel producto, {
    required int cantidad,
  }) async {
    if (widget.mesaId == null) {
      _mostrarMensaje(
        'No hay mesa vinculada. Escaneá el QR de mesa para pedir.',
        esError: true,
      );
      return;
    }

    setState(() => _agregando = true);
    try {
      await _pedidosRepository.agregarProducto(
        mesaId: widget.mesaId!,
        producto: producto,
        cantidad: cantidad,
      );
      if (!mounted) return;
      await _cargarResumenPedido();
      _mostrarMensaje(
        '${producto.nombre} x$cantidad agregado al pedido.',
        esError: false,
      );
    } catch (error) {
      if (!mounted) return;
      _mostrarMensaje(
        AppErrorMapper.toUserMessage(
          error,
          fallbackMessage: 'No se pudo agregar el producto al pedido.',
        ),
        esError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _agregando = false);
      }
    }
  }

  Future<void> _abrirVistaPreviaProducto(ProductoModel producto) async {
    if (widget.mesaId == null) {
      _mostrarMensaje(
        'No hay mesa vinculada. Escaneá el QR de mesa para pedir.',
        esError: true,
      );
      return;
    }

    final cantidad = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.9,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: _ProductoClienteCard(
                producto: producto,
                onAgregarAlPedido:
                    (cantidadSeleccionada) =>
                        Navigator.of(sheetContext).pop(cantidadSeleccionada),
                onVerDetalle: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProductoDetallePage(producto: producto),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );

    if (!mounted || cantidad == null) return;
    await _onAgregarAlPedido(producto, cantidad: cantidad);
  }

  void _mostrarMensaje(String mensaje, {required bool esError}) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor:
              esError ? const Color(0xFF992E2E) : const Color(0xFF2D6A4F),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    const titulo = 'Carta de productos';

    return Scaffold(
      appBar: AppBar(
        title: Text(titulo),
        actions: [
          IconButton(
            onPressed: () {
              _searchController.clear();
              _cargar();
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Recargar',
          ),
        ],
      ),
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
            children: [
              // ── Buscador ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onBuscar,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF8D2628),
                    hintText: 'Buscar por nombre...',
                    hintStyle: const TextStyle(color: Colors.white54),
                    prefixIcon: const Icon(Icons.search, color: Colors.white54),
                    suffixIcon:
                        _searchController.text.isNotEmpty
                            ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: Colors.white54,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                _onBuscar('');
                              },
                            )
                            : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Todos'),
                      selected: _categoria == 'todos',
                      onSelected: (_) => _onCambiarCategoria('todos'),
                    ),
                    ChoiceChip(
                      label: const Text('Platos'),
                      selected: _categoria == 'plato',
                      onSelected: (_) => _onCambiarCategoria('plato'),
                    ),
                    ChoiceChip(
                      label: const Text('Bebidas'),
                      selected: _categoria == 'bebida',
                      onSelected: (_) => _onCambiarCategoria('bebida'),
                    ),
                  ],
                ),
              ),

              if (widget.mesaId != null)
                Container(
                  margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3F1213),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFFFE2A8),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TOTAL ACUMULADO',
                              style: TextStyle(
                                color: Color(0xFFFFE2A8),
                                fontSize: 11,
                                letterSpacing: 0.6,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _resumenPedido == null
                                  ? '\$0.00'
                                  : '\$${((_resumenPedido!['subtotal'] as num?) ?? 0).toStringAsFixed(2)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                height: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7A2021),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'TIEMPO',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _resumenPedido == null
                                    ? '0 minutos'
                                    : '${_resumenPedido!['tiempoTotalMin']} minutos',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Contenido ─────────────────────────────────────────────
              Expanded(
                child:
                    _cargando
                        ? const Center(
                          child: LogoSpinner(size: 60, strokeWidth: 4),
                        )
                        : _error != null
                        ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _error!,
                                style: const TextStyle(color: Colors.white70),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF2D6A4F),
                                ),
                                onPressed: () => _cargar(),
                                child: const Text('Reintentar'),
                              ),
                            ],
                          ),
                        )
                        : _productos.isEmpty
                        ? const Center(
                          child: Text(
                            'No hay productos disponibles.',
                            style: TextStyle(color: Colors.white70),
                          ),
                        )
                        : Column(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  12,
                                  8,
                                  12,
                                  8,
                                ),
                                child: Column(
                                  children:
                                      _productosPagina.map((producto) {
                                        return Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 8,
                                            ),
                                            child: _ProductoClienteListItem(
                                              producto: producto,
                                              onTapProducto:
                                                  () =>
                                                      _abrirVistaPreviaProducto(
                                                        producto,
                                                      ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed:
                                          _paginaActual == 0
                                              ? null
                                              : _irPaginaAnterior,
                                      style: OutlinedButton.styleFrom(
                                        minimumSize: const Size.fromHeight(40),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 8,
                                        ),
                                        foregroundColor: const Color(
                                          0xFF4A0E10,
                                        ),
                                        backgroundColor: Colors.white,
                                        disabledForegroundColor: Colors.white54,
                                        disabledBackgroundColor: const Color(
                                          0xFF7A2021,
                                        ),
                                        side: const BorderSide(
                                          color: Colors.white,
                                          width: 1.4,
                                        ),
                                        textStyle: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                      icon: const Icon(
                                        Icons.chevron_left,
                                        size: 18,
                                      ),
                                      label: const Text('Anterior'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Página ${_paginaActual + 1} / $_totalPaginas',
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed:
                                          _paginaActual >= _totalPaginas - 1
                                              ? null
                                              : _irPaginaSiguiente,
                                      style: OutlinedButton.styleFrom(
                                        minimumSize: const Size.fromHeight(40),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 8,
                                        ),
                                        foregroundColor: const Color(
                                          0xFF4A0E10,
                                        ),
                                        backgroundColor: Colors.white,
                                        disabledForegroundColor: Colors.white54,
                                        disabledBackgroundColor: const Color(
                                          0xFF7A2021,
                                        ),
                                        side: const BorderSide(
                                          color: Colors.white,
                                          width: 1.4,
                                        ),
                                        textStyle: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                      icon: const Icon(
                                        Icons.chevron_right,
                                        size: 18,
                                      ),
                                      label: const Text('Siguiente'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
              ),

              if (_agregando)
                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: LogoSpinner(size: 26, strokeWidth: 2),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductoClienteListItem extends StatelessWidget {
  const _ProductoClienteListItem({
    required this.producto,
    required this.onTapProducto,
  });

  final ProductoModel producto;
  final VoidCallback onTapProducto;

  @override
  Widget build(BuildContext context) {
    final esPlato = producto.tipo == 'plato';

    return Card(
      color: const Color(0xFFA02C2C),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFFFC9C9), width: 0.6),
      ),
      elevation: 2,
      child: InkWell(
        onTap: onTapProducto,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.all(9),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  producto.foto1,
                  width: 68,
                  height: 68,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (_, __, ___) => Container(
                        width: 68,
                        height: 68,
                        color: Colors.white12,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.broken_image,
                          color: Colors.white60,
                        ),
                      ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      producto.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      producto.descripcion,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFFFDDDD),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _DatoMini(
                          icon: esPlato ? Icons.restaurant : Icons.local_bar,
                          text: esPlato ? 'Plato' : 'Bebida',
                        ),
                        _DatoMini(
                          icon: Icons.access_time,
                          text: '${producto.tiempoMin} min',
                        ),
                        _DatoMini(
                          icon: Icons.attach_money,
                          text: '\$${producto.precio.toStringAsFixed(2)}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Colors.white70),
            ],
          ),
        ),
      ),
    );
  }
}

class _DatoMini extends StatelessWidget {
  const _DatoMini({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF9A3A3A),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFFFB9B9)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white70),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  _ProductoClienteCard
//  Card blanca estilo _MesaEditorCard con carrusel + info tiles
//  + botones de acción para el flujo de pedidos.
// ─────────────────────────────────────────────────────────────
class _ProductoClienteCard extends StatefulWidget {
  const _ProductoClienteCard({
    required this.producto,
    required this.onAgregarAlPedido,
    required this.onVerDetalle,
  });

  final ProductoModel producto;
  final ValueChanged<int> onAgregarAlPedido;
  final VoidCallback onVerDetalle;

  @override
  State<_ProductoClienteCard> createState() => _ProductoClienteCardState();
}

class _ProductoClienteCardState extends State<_ProductoClienteCard> {
  final PageController _fotoController = PageController();
  final TextEditingController _cantidadController = TextEditingController(
    text: '1',
  );

  int _fotoActual = 0;
  int _cantidad = 1;

  @override
  void dispose() {
    _fotoController.dispose();
    _cantidadController.dispose();
    super.dispose();
  }

  void _setCantidad(int nuevaCantidad) {
    final valor = nuevaCantidad.clamp(1, 99);
    setState(() {
      _cantidad = valor;
      _cantidadController.text = '$valor';
      _cantidadController.selection = TextSelection.fromPosition(
        TextPosition(offset: _cantidadController.text.length),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.producto;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Título ──────────────────────────────────────────────
            Text(
              p.nombre,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'ArchivoBlack',
                fontSize: 28,
                color: Color(0xFF3D1F1F),
                letterSpacing: -1.0,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),

            // ── Carrusel de fotos ───────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                height: 220,
                child: Stack(
                  children: [
                    PageView.builder(
                      controller: _fotoController,
                      itemCount: p.fotos.length,
                      onPageChanged: (i) => setState(() => _fotoActual = i),
                      itemBuilder:
                          (_, i) => Image.network(
                            p.fotos[i],
                            fit: BoxFit.cover,
                            width: double.infinity,
                            loadingBuilder:
                                (_, child, progress) =>
                                    progress == null
                                        ? child
                                        : const Center(
                                          child: CircularProgressIndicator(
                                            color: Color(0xFF7A2021),
                                          ),
                                        ),
                            errorBuilder:
                                (_, __, ___) => Container(
                                  color: const Color(0xFFF0F0F0),
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.broken_image,
                                    color: Color(0xFF8A8A8A),
                                    size: 48,
                                  ),
                                ),
                          ),
                    ),

                    // Indicadores del carrusel
                    Positioned(
                      bottom: 10,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(p.fotos.length, (i) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: _fotoActual == i ? 18 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color:
                                  _fotoActual == i
                                      ? Colors.white
                                      : Colors.white60,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ── Info tiles ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF2E6E6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFD8BBBB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _ProductoInfoTile(
                          icon: Icons.attach_money,
                          label: 'Precio',
                          value: '\$${p.precio.toStringAsFixed(2)}',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ProductoInfoTile(
                          icon: Icons.access_time,
                          label: 'Tiempo',
                          value: '${p.tiempoMin} min',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _ProductoInfoTile(
                    icon:
                        p.tipo == 'plato' ? Icons.restaurant : Icons.local_bar,
                    label: 'Descripción',
                    value: p.descripcion,
                    fullWidth: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Botón ver detalle ───────────────────────────────────
            OutlinedButton.icon(
              onPressed: widget.onVerDetalle,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF7A2021),
                backgroundColor: const Color(0xFFFFF4F4),
                side: const BorderSide(color: Color(0xFF7A2021), width: 1.4),
                minimumSize: const Size.fromHeight(50),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              icon: const Icon(Icons.info_outline, size: 20),
              label: const Text('Ver detalle'),
            ),
            const SizedBox(height: 10),

            // ── Selector de cantidad ────────────────────────────────
            Row(
              children: [
                IconButton.filledTonal(
                  onPressed: () => _setCantidad(_cantidad - 1),
                  icon: const Icon(Icons.remove),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _cantidadController,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                    ],
                    onChanged: (value) {
                      final parsed = int.tryParse(value);
                      if (parsed == null) return;
                      _setCantidad(parsed);
                    },
                    decoration: const InputDecoration(
                      labelText: 'Cantidad',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filled(
                  onPressed: () => _setCantidad(_cantidad + 1),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Botón agregar al pedido ─────────────────────────────
            FilledButton.icon(
              onPressed: () => widget.onAgregarAlPedido(_cantidad),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                backgroundColor: const Color(0xFF2D6A4F),
                foregroundColor: Colors.white,
                textStyle: const TextStyle(
                  fontFamily: 'ArchivoBlack',
                  fontSize: 16,
                  letterSpacing: 0.3,
                ),
              ),
              icon: const Icon(Icons.add_shopping_cart, size: 22),
              label: const Text('Agregar al pedido'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  _ProductoInfoTile  (mismo patrón que _MesaInfoTile)
// ─────────────────────────────────────────────────────────────
class _ProductoInfoTile extends StatelessWidget {
  const _ProductoInfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.fullWidth = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF4F4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4CDCD)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF7A2021)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF7E5858),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF3D1F1F),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
