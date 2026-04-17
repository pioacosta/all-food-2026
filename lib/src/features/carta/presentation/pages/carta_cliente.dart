import 'package:all_food/src/features/carta/data/repositories/carta_repository.dart';
import 'package:all_food/src/features/carta/data/models/producto_model.dart';
import 'package:all_food/src/features/pedidos/data/repositories/pedidos_repository.dart';
import 'package:all_food/src/shared/errors/app_error_mapper.dart';
import 'package:all_food/src/shared/widgets/logo_spinner.dart';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────
//  CartaClientePage
//  Recibe [tipo] ('plato' | 'bebida') igual que CartaPage,
//  de modo que el flujo puede instanciarla para cada sección.
// ─────────────────────────────────────────────────────────────
class CartaClientePage extends StatefulWidget {
  const CartaClientePage({
    required this.tipo,
    this.mesaId,
    this.numeroMesa,
    super.key,
  });

  final String tipo;
  final String? mesaId;
  final int? numeroMesa;

  @override
  State<CartaClientePage> createState() => _CartaClientePageState();
}

class _CartaClientePageState extends State<CartaClientePage> {
  final _repository = CartaRepository();
  final _pedidosRepository = PedidosRepository();
  final _pageController = PageController();
  final _searchController = TextEditingController();

  List<ProductoModel> _productos = [];
  bool _cargando = true;
  bool _agregando = false;
  String? _error;
  Map<String, dynamic>? _resumenPedido;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargar({String? nombre}) async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final data = await _repository.getProductos(
        tipo: widget.tipo,
        nombre: nombre,
      );

      if (!mounted) return;
      setState(() {
        _productos = data.map(ProductoModel.fromMap).toList();
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

  Future<void> _onAgregarAlPedido(ProductoModel producto) async {
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
      );
      if (!mounted) return;
      await _cargarResumenPedido();
      _mostrarMensaje('${producto.nombre} agregado al pedido.', esError: false);
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

  // ── Placeholder: se implementará cuando continúes el flujo de detalle ──
  void _onVerDetalle(ProductoModel producto) {
    // TODO: navegar a ProductoDetallePage o modal de detalle
  }

  @override
  Widget build(BuildContext context) {
    final titulo =
        widget.tipo == 'plato' ? 'Carta de platos' : 'Carta de bebidas';

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

              // ── Hint de navegación ────────────────────────────────────
              if (!_cargando && _productos.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 6),
                  child: Text(
                    'Deslizá verticalmente para ver más productos',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),

              if (widget.mesaId != null)
                Container(
                  margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _resumenPedido == null
                              ? 'Pedido vacío'
                              : 'Total: \$${((_resumenPedido!['subtotal'] as num?) ?? 0).toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          _resumenPedido == null
                              ? 'Tiempo: 0 min'
                              : 'Tiempo: ${_resumenPedido!['tiempoTotalMin']} min',
                          textAlign: TextAlign.end,
                          style: const TextStyle(color: Colors.white70),
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
                        : PageView.builder(
                          controller: _pageController,
                          scrollDirection: Axis.vertical,
                          itemCount: _productos.length,
                          itemBuilder: (context, index) {
                            final producto = _productos[index];
                            return Padding(
                              padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                              child: _ProductoClienteCard(
                                producto: producto,
                                index: index,
                                total: _productos.length,
                                onAgregarAlPedido:
                                    () => _onAgregarAlPedido(producto),
                                onVerDetalle: () => _onVerDetalle(producto),
                              ),
                            );
                          },
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

// ─────────────────────────────────────────────────────────────
//  _ProductoClienteCard
//  Card blanca estilo _MesaEditorCard con carrusel + info tiles
//  + botones de acción para el flujo de pedidos.
// ─────────────────────────────────────────────────────────────
class _ProductoClienteCard extends StatefulWidget {
  const _ProductoClienteCard({
    required this.producto,
    required this.index,
    required this.total,
    required this.onAgregarAlPedido,
    required this.onVerDetalle,
  });

  final ProductoModel producto;
  final int index;
  final int total;
  final VoidCallback onAgregarAlPedido;
  final VoidCallback onVerDetalle;

  @override
  State<_ProductoClienteCard> createState() => _ProductoClienteCardState();
}

class _ProductoClienteCardState extends State<_ProductoClienteCard> {
  final PageController _fotoController = PageController();
  int _fotoActual = 0;

  @override
  void dispose() {
    _fotoController.dispose();
    super.dispose();
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
            // ── Contador de posición ────────────────────────────────
            Text(
              'Producto ${widget.index + 1} de ${widget.total}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF6A6A6A)),
            ),
            const SizedBox(height: 10),

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

            // ── Botón agregar al pedido ─────────────────────────────
            FilledButton.icon(
              onPressed: widget.onAgregarAlPedido,
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
