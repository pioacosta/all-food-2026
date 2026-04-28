import 'package:flutter/material.dart';
import 'dart:ui';

import 'package:all_food/src/features/carta/data/repositories/carta_repository.dart';
import 'package:all_food/src/features/carta/data/models/producto_model.dart';
import 'package:all_food/src/features/carta/presentation/widgets/producto_cliente_card.dart';
import 'package:all_food/src/features/pedidos/data/repositories/pedidos_repository.dart';
import 'package:all_food/src/features/pedidos/presentation/pages/cliente_pedido_page.dart';
import 'package:all_food/src/shared/errors/app_error_mapper.dart';
import 'package:all_food/src/shared/widgets/logo_spinner.dart';
import 'package:all_food/src/shared/utils/error_feedback.dart';
import 'package:flutter/services.dart';

// ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?
//  CartaClientePage
//  Recibe [tipo] ('plato' | 'bebida') igual que CartaPage,
//  de modo que el flujo puede instanciarla para cada secci?fï¿½n.
// ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?
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
  // En cliente usamos 3 ?fï¿½tems por p?fï¿½gina para evitar overflow en pantallas
  // chicas al combinar filtros + resumen + paginaci?fï¿½n.
  static const int _itemsPorPagina = 4;
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
              child: ProductoClienteCard(
                producto: producto,
                onAgregarAlPedido:
                    (cantidadSeleccionada) =>
                        Navigator.of(sheetContext).pop(cantidadSeleccionada),
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
              // ï¿½????,?ï¿½????,? Buscador ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onBuscar,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white10,
                    hintText: 'Buscar por nombre...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFFF5F5DC),
                      size: 22,
                    ),
                    suffixIcon:
                        _searchController.text.isNotEmpty
                            ? IconButton(
                              icon: const Icon(
                                Icons.clear_rounded,
                                color: Color(0xFFF5F5DC),
                                size: 20,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                _onBuscar('');
                              },
                            )
                            : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Color(0xFFF5F5DC),
                        width: 1.2,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: const Color(0xFFF5F5DC).withOpacity(0.4),
                        width: 1.2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Color(0xFFF5F5DC),
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
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

              // ï¿½????,?ï¿½????,? Contenido ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?
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
                            // ï¿½????,?ï¿½????,? Grid 2x2 ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  12,
                                  8,
                                  12,
                                  8,
                                ),
                                child: GridView.count(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                  childAspectRatio: 0.82,
                                  children:
                                      _productosPagina
                                          .map(
                                            (producto) => _ProductoCard(
                                              producto: producto,
                                              onTap:
                                                  () =>
                                                      _abrirVistaPreviaProducto(
                                                        producto,
                                                      ),
                                            ),
                                          )
                                          .toList(),
                                ),
                              ),
                            ),
                            // ï¿½????,?ï¿½????,? Paginaci?fï¿½n ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    onPressed:
                                        _paginaActual == 0
                                            ? null
                                            : _irPaginaAnterior,
                                    icon: Icon(
                                      Icons
                                          .chevron_left_rounded, // ï¿½???ï¿½ rounded se ve m?fï¿½s grueso
                                      color:
                                          _paginaActual == 0
                                              ? Colors.white24
                                              : Colors.white70,
                                      size: 36, // ï¿½???ï¿½ m?fï¿½s grande
                                    ),
                                  ),
                                  Text(
                                    '${_paginaActual + 1} / $_totalPaginas',
                                    style: const TextStyle(
                                      color:
                                          Colors
                                              .white70, // ï¿½???ï¿½ un poco m?fï¿½s visible
                                      fontSize: 16, // ï¿½???ï¿½ m?fï¿½s grande
                                      fontWeight:
                                          FontWeight
                                              .w800, // ï¿½???ï¿½ m?fï¿½s grueso
                                    ),
                                  ),
                                  IconButton(
                                    onPressed:
                                        _paginaActual >= _totalPaginas - 1
                                            ? null
                                            : _irPaginaSiguiente,
                                    icon: Icon(
                                      Icons
                                          .chevron_right_rounded, // ï¿½???ï¿½ rounded se ve m?fï¿½s grueso
                                      color:
                                          _paginaActual >= _totalPaginas - 1
                                              ? Colors.white24
                                              : Colors.white70,
                                      size: 36, // ï¿½???ï¿½ m?fï¿½s grande
                                    ),
                                  ),
                                ],
                              ),
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
                    border: Border.all(color: Colors.white24, width: 0.8),
                  ),
                  child: Row(
                    children: [
                      // ï¿½????,?ï¿½????,? Total + Tiempo ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?
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
                                  ? '\$0'
                                  : _formatPrecio(
                                    (_resumenPedido!['subtotal'] as num?) ?? 0,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  size: 13,
                                  color: Colors.white54,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _resumenPedido == null
                                      ? '0 minutos'
                                      : '${_resumenPedido!['tiempoTotalMin']} minutos de espera',
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // ï¿½????,?ï¿½????,? Bot?fï¿½n ver pedido ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => ClientePedidoPage(
                                    mesaId: widget.mesaId!,
                                    numeroMesa: widget.numeroMesa ?? 0,
                                  ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2D6A4F),

                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.receipt_long,
                                color: Color(0xFFF5F5DC),
                                size: 22,
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Ver pedido',
                                style: TextStyle(
                                  color: Color(0xFFFFFFFF),
                                  fontSize: 12,
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

String _formatPrecio(num valor) {
  return '\$${valor.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
}

class _ProductoCard extends StatelessWidget {
  const _ProductoCard({required this.producto, required this.onTap});

  final ProductoModel producto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
            width: 0.8,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ï¿½????,?ï¿½????,? Foto ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
                child: ColorFiltered(
                  colorFilter: ColorFilter.matrix([
                    0.90, 0, 0, 0, 0, // R
                    0, 0.90, 0, 0, 0, // G
                    0, 0, 0.90, 0, 0, // B
                    0, 0, 0, 1, 0, // A
                  ]),
                  child: Image.network(
                    producto.foto1,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (_, __, ___) => Container(
                          color: const Color(0xFFD4C9A8),
                          child: const Center(
                            child: Icon(
                              Icons.restaurant,
                              color: Color(0xFF5B1718),
                              size: 40,
                            ),
                          ),
                        ),
                  ),
                ),
              ),
            ),
            // ï¿½????,?ï¿½????,? Nombre y precio ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?ï¿½????,?
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    producto.nombre,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // PRECIO
                      Text(
                        _formatPrecio(producto.precio),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFF5F5DC),
                        ),
                      ),
                      // TIEMPO
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 14,
                            color: Color(0xFFF5F5DC),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${producto.tiempoMin} min',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFF5F5DC),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
