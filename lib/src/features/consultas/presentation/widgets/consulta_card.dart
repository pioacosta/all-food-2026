import 'package:flutter/material.dart';

enum Urgencia { normal, media, urgente }

class ConsultaCard extends StatelessWidget {
  const ConsultaCard({
    super.key,
    required this.mesaNumero,
    required this.nombreCliente,
    required this.previewTexto,
    required this.previewHora,
    required this.urgenciaTexto,
    required this.urgenciaNivel,
    required this.onTap,
  });

  final String mesaNumero;
  final String nombreCliente;
  final String previewTexto;
  final String previewHora;
  final String urgenciaTexto;
  final Urgencia urgenciaNivel;
  final VoidCallback onTap;

  Color get _urgenciaColor => switch (urgenciaNivel) {
    Urgencia.urgente => const Color(0xFFE24B4A),
    Urgencia.media => const Color(0xFFEF9F27),
    Urgencia.normal => Colors.transparent,
  };

  @override
  Widget build(BuildContext context) {
    final tieneUrgencia = urgenciaNivel != Urgencia.normal;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          // ── Fondo semitransparente como en tu screenshot ───────
          color: Colors.transparent,
        ),
        child: Row(
          children: [
            // ── Borde lateral de urgencia ──────────────────────
            if (tieneUrgencia)
              Container(
                width: 4,
                height: 80,
                decoration: BoxDecoration(
                  color: _urgenciaColor,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(16),
                  ),
                ),
              ),

            // ── Número de mesa ─────────────────────────────────
            Padding(
              padding: EdgeInsets.only(
                left: tieneUrgencia ? 12 : 16,
                right: 14,
                top: 16,
                bottom: 16,
              ),
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      mesaNumero,
                      style: const TextStyle(
                        fontFamily: 'ArchivoBlack',
                        fontSize: 20,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                    const Text(
                      'MESA',
                      style: TextStyle(
                        fontSize: 8,
                        letterSpacing: 1,
                        color: Colors.white60,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Info ───────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre + hora
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            nombreCliente,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (previewHora.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Text(
                              previewHora,
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    tieneUrgencia
                                        ? _urgenciaColor
                                        : Colors.white38,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Preview mensaje
                    Text(
                      previewTexto,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white60,
                        height: 1.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Badge urgencia
                    if (tieneUrgencia) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _urgenciaColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: _urgenciaColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              urgenciaTexto,
                              style: TextStyle(
                                fontSize: 11,
                                color: _urgenciaColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // ── Flecha ─────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.only(right: 14),
              child: Icon(
                Icons.chevron_right_rounded,
                color: Colors.white30,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
