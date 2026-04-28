import 'dart:ui';
import 'package:all_food/src/shared/widgets/logo_spinner.dart';
import 'package:flutter/material.dart';

class FotoVisorDialog extends StatefulWidget {
  const FotoVisorDialog({ super.key, required this.fotos, required this.indiceInicial });

  final List<String> fotos;
  final int indiceInicial;

  @override
  State<FotoVisorDialog> createState() => FotoVisorDialogState();
}

class FotoVisorDialogState extends State<FotoVisorDialog> {
  late final PageController _pageController;
  late int _indiceActual;

  @override
  void initState() {
    super.initState();
    _indiceActual = widget.indiceInicial;
    _pageController = PageController(initialPage: widget.indiceInicial);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Fondo difuminado — cubre toda la pantalla
        Positioned.fill(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(color: Colors.black.withValues(alpha: 0.55)),
            ),
          ),
        ),

        // Contenido centrado
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Contador de fotos
              if (widget.fotos.length > 1)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    '${_indiceActual + 1} / ${widget.fotos.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

              // Imagen grande con swipe entre fotos
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.55,
                width: MediaQuery.of(context).size.width,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: widget.fotos.length,
                  onPageChanged: (i) => setState(() => _indiceActual = i),
                  itemBuilder:
                      (_, i) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.network(
                            widget.fotos[i],
                            fit: BoxFit.contain,
                            loadingBuilder:
                                (_, child, progress) =>
                                    progress == null
                                        ? child
                                        : const Center(
                                          child: LogoSpinner(size: 22, strokeWidth: 2),
                                        ),
                            errorBuilder:
                                (_, __, ___) => Container(
                                  color: const Color(0xFF2A2A2A),
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.broken_image,
                                    color: Colors.white38,
                                    size: 64,
                                  ),
                                ),
                          ),
                        ),
                      ),
                ),
              ),

              // indicadores de pag
              if (widget.fotos.length > 1) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.fotos.length, (i) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _indiceActual == i ? 20 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color:
                            _indiceActual == i ? Colors.white : Colors.white38,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              ],

              const SizedBox(height: 24),

              // Botón cerrar
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white30),
                  ),
                  child: const Text(
                    'Cerrar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
