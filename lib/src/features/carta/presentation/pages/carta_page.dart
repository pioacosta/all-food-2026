import 'package:all_food/src/features/carta/data/repositories/carta_repository.dart';
import 'package:all_food/src/features/carta/data/models/producto_model.dart';
import 'package:all_food/src/features/carta/presentation/pages/producto_detalle_page.dart';
import 'package:all_food/src/shared/errors/app_error_mapper.dart';
import 'package:all_food/src/shared/widgets/logo_spinner.dart';
import 'package:flutter/material.dart';

class CartaPage extends StatefulWidget {
  const CartaPage({required this.tipo, super.key});

  final String tipo;

  @override
  State<CartaPage> createState() => _CartaPageState();
}

class _CartaPageState extends State<CartaPage> {
  final _repository = CartaRepository();
  final _searchController = TextEditingController();

  List<ProductoModel> _productos = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
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

  void _onBuscar(String valor) {
    _cargar(nombre: valor.isEmpty ? null : valor);
  }

  @override
  Widget build(BuildContext context) {
    final titulo =
        widget.tipo == 'plato' ? 'Carta de platos' : 'Carta de bebidas';

    return Scaffold(
      appBar: AppBar(title: Text(titulo)),
      body: Container(
        color: const Color(0xFF5A0F10), 
        child: Column(
          children: [
            // 🔍 Buscador
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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

            // 📋 Contenido
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
                        scrollDirection: Axis.vertical,
                        itemCount: _productos.length,
                        itemBuilder: (context, index) {
                          return _ProductoCard(
                            producto: _productos[index],
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => ProductoDetallePage(
                                        producto: _productos[index],
                                      ),
                                ),
                              );
                            },
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Card tipo reel ─────────────────────────────────────────────

class _ProductoCard extends StatefulWidget {
  const _ProductoCard({required this.producto, required this.onTap});

  final ProductoModel producto;
  final VoidCallback onTap;

  @override
  State<_ProductoCard> createState() => _ProductoCardState();
}

class _ProductoCardState extends State<_ProductoCard> {
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

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF8D2628), // 🍷 card estilo login
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 📸 Carrusel
            Expanded(
              flex: 6,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
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
                                            color: Colors.white,
                                          ),
                                        ),
                            errorBuilder:
                                (_, __, ___) => const Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    color: Colors.white38,
                                    size: 48,
                                  ),
                                ),
                          ),
                    ),

                    // indicadores
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
                                      : Colors.white38,
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

            // 📝 Info
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.nombre,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontFamily: 'ArchivoBlack',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      p.descripcion,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 20,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              color: Colors.white54,
                              size: 25,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${p.tiempoMin} min',
                              style: const TextStyle(color: Colors.white54, fontSize: 20),
                            ),
                          ],
                        ),
                        Text(
                          '\$${p.precio.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Color.fromARGB(
                              255,
                              250,
                              250,
                              250,
                            ), // 💰 dorado
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
