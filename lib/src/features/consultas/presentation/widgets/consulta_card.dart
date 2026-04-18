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
    Urgencia.urgente => const Color(0xFFFFF2B2),
    Urgencia.media => const Color(0xFFB6F0FF),
    Urgencia.normal => Colors.transparent,
  };

  Color get _urgenciaBadgeBg => switch (urgenciaNivel) {
    Urgencia.urgente => const Color(0xFF2A3340),
    Urgencia.media => const Color(0xFF223844),
    Urgencia.normal => Colors.transparent,
  };

  Color get _urgenciaStripeColor => switch (urgenciaNivel) {
    Urgencia.urgente => const Color(0xFFFFE08A),
    Urgencia.media => const Color(0xFF93E9FF),
    Urgencia.normal => Colors.transparent,
  };

  Color get _horaColor => switch (urgenciaNivel) {
    Urgencia.urgente => const Color(0xFFFFE8AD),
    Urgencia.media => const Color(0xFFC7F2FF),
    Urgencia.normal => const Color(0xFFE8C8CB),
  };

  @override
  Widget build(BuildContext context) {
    final tieneUrgencia = urgenciaNivel != Urgencia.normal;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF7E1D23).withOpacity(0.38),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFC7767D), width: 0.8),
        ),
        child: Row(
          children: [
            // ── Borde lateral de urgencia ──────────────────────
            if (tieneUrgencia)
              Container(
                width: 4,
                height: 80,
                decoration: BoxDecoration(
                  color: _urgenciaStripeColor,
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
                  color: const Color(0xFF9A4A50).withOpacity(0.55),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFDD9EA3),
                    width: 0.8,
                  ),
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
                              style: TextStyle(fontSize: 12, color: _horaColor),
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
                        color: Color(0xFFFFDDE0),
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
                          color: _urgenciaBadgeBg,
                          border: Border.all(
                            color: _urgenciaColor.withOpacity(0.5),
                            width: 0.8,
                          ),
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
                color: Color(0xFFFFD1D4),
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
