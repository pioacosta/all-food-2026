import 'package:all_food/src/features/carta/data/models/producto_model.dart';
import 'package:flutter/material.dart';

class ProductoDetallePage extends StatefulWidget {
  const ProductoDetallePage({required this.producto, super.key});

  final ProductoModel producto;

  @override
  State<ProductoDetallePage> createState() => _ProductoDetallePageState();
}

class _ProductoDetallePageState extends State<ProductoDetallePage> {
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

    return Scaffold(
      backgroundColor: const Color(0xFF5A0F10),
      appBar: AppBar(title: Text(p.nombre)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 📸 Carrusel grande
            SizedBox(
              height: 320,
              child: Stack(
                children: [
                  PageView.builder(
                    controller: _fotoController,
                    itemCount: p.fotos.length,
                    onPageChanged: (i) => setState(() => _fotoActual = i),
                    itemBuilder: (_, i) => Image.network(
                      p.fotos[i],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      loadingBuilder: (_, child, progress) =>
                          progress == null
                              ? child
                              : const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                ),
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(
                          Icons.broken_image,
                          color: Colors.white38,
                          size: 56,
                        ),
                      ),
                    ),
                  ),

                  // Indicadores
                  Positioned(
                    bottom: 12,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(p.fotos.length, (i) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: _fotoActual == i ? 22 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _fotoActual == i
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

            // 📝 Detalle
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.nombre,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34, // ⬆️ antes 28
                      fontFamily: 'ArchivoBlack',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    p.descripcion,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 20, // ⬆️ antes 16
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          color: Colors.white54, size: 25), // ⬆️ antes 20
                      const SizedBox(width: 6),
                      Text(
                        '${p.tiempoMin} min de elaboración',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 20, // ⬆️ agregado
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '\$${p.precio.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Color.fromARGB(255, 255, 255, 255),
                      fontSize: 36, // ⬆️ antes 32
                      fontWeight: FontWeight.bold,
                    ),
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