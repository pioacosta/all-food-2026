// ─────────────────────────────────────────────────────────────
//  _ProductoClienteCard
//  Card blanca estilo _MesaEditorCard con carrusel + info tiles
//  + botones de acción para el flujo de pedidos.
// ─────────────────────────────────────────────────────────────
import 'package:all_food/src/features/carta/data/models/producto_model.dart';
import 'package:all_food/src/features/carta/presentation/widgets/foto_visor_dialog.dart';
import 'package:all_food/src/shared/widgets/logo_spinner.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProductoClienteCard extends StatefulWidget {
  const ProductoClienteCard({
    super.key,
    required this.producto,
    required this.onAgregarAlPedido,
  });

  final ProductoModel producto;
  final ValueChanged<int> onAgregarAlPedido;

  @override
  State<ProductoClienteCard> createState() => _ProductoClienteCardState();
}

class _ProductoClienteCardState extends State<ProductoClienteCard> {
  final PageController _fotoController = PageController();
  final TextEditingController _cantidadController = TextEditingController(
    text: '1',
  );

  int _fotoActual = 0;
  int _cantidad = 1;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final fotos = widget.producto.fotos;

      for (var url in fotos) {
        if (url.isNotEmpty) {
          precacheImage(CachedNetworkImageProvider(url), context);
        }
      }
    });
  }

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

  void _abrirVisorFoto(BuildContext context, int indiceInicial) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder:
          (_) => FotoVisorDialog(
            fotos: widget.producto.fotos,
            indiceInicial: indiceInicial,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.producto;

    return Container(
      decoration: BoxDecoration(
        color: Color(0xFFF5F5DC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Carrusel de fotos (arriba, sin padding) ─────────────
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              child: SizedBox(
                height: 280,
                child: Stack(
                  children: [
                    PageView(
                      controller: _fotoController,
                      onPageChanged: (i) => setState(() => _fotoActual = i),
                      children:
                          p.fotos.map((url) {
                            return GestureDetector(
                              onTap:
                                  () => _abrirVisorFoto(
                                    context,
                                    p.fotos.indexOf(url),
                                  ),
                              child: CachedNetworkImage(
                                imageUrl: url,
                                fit: BoxFit.cover,
                                width: double.infinity,

                                placeholder:
                                    (context, url) => const Center(
                                      child: LogoSpinner(
                                        size: 40,
                                        color: Color(0xFF3D1F1F),
                                      ),
                                    ),

                                errorWidget:
                                    (context, url, error) => Container(
                                      color: const Color(0xFFF0F0F0),
                                      alignment: Alignment.center,
                                      child: const Icon(
                                        Icons.broken_image,
                                        color: Color(0xFF8A8A8A),
                                        size: 48,
                                      ),
                                    ),
                              ),
                            );
                          }).toList(),
                    ),

                    // Indicadores de puntos
                    if (p.fotos.length > 1)
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

                    // Hint lupa
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.zoom_out_map_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Resto del contenido con padding ─────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Nombre ────────────────────────────────────────
                  Text(
                    p.nombre,
                    style: const TextStyle(
                      fontFamily: 'ArchivoBlack',
                      fontSize: 26,
                      color: Color(0xFF3D1F1F),
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // ── Descripción ───────────────────────────────────
                  Text(
                    p.descripcion,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF6B5050),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Precio ────────────────────────────────────────
                  _InfoRow(
                    icon: Icons.attach_money_rounded,
                    label: 'Precio',
                    value: '\$${p.precio.toStringAsFixed(2)}',
                    valueColor: const Color(0xFF1A7A4A),
                  ),
                  const SizedBox(height: 10),

                  // ── Tiempo ────────────────────────────────────────
                  _InfoRow(
                    icon: Icons.access_time_rounded,
                    label: 'Tiempo en minutos',
                    value: '${p.tiempoMin}',
                    valueColor: const Color(0xFF1A7A4A),
                  ),
                  const SizedBox(height: 24),

                  // ── Selector de cantidad ──────────────────────────
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
                            
                            border: OutlineInputBorder(),
                            isDense: true,
                            filled: true,
                            fillColor: Color(
                              0xFFF5F5DC,
                            ), // mismo crema del fondo
                            labelStyle: TextStyle(color: Color(0xFF3D1F1F)),
                          ),
                          style: const TextStyle(
                            color: Color(0xFF3D1F1F),
                            fontSize: 18,
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
                  const SizedBox(height: 14),

                  // ── Botón agregar al pedido ───────────────────────
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
          ],
        ),
      ),
    );
  }
}

// Info del producto CARTA
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5DC),
        borderRadius: BorderRadius.circular(12),
        // border: Border(
        //   bottom: BorderSide(color: const Color(0xFF8D2628), width: 3),
        // ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 25, color: const Color(0xFF3D1F1F)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3D1F1F),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF8D2628),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
