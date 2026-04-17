// ─── Burbuja de mensaje ───────────────────────────────────────────────────────
import 'package:flutter/material.dart';

class BurbujaMensaje extends StatelessWidget {
  final String mensaje;
  final bool esMio;
  final String? hora;
  final String? fecha;
  final String? nombreEmisor;
  final String? perfilEmisor;
  final String? numeroMesa;

  const BurbujaMensaje({
    super.key,
    required this.mensaje,
    required this.esMio,
    this.hora,
    this.fecha,
    this.nombreEmisor,
    this.perfilEmisor,
    this.numeroMesa,
  });

  @override
  Widget build(BuildContext context) {
    String? tagInfo;
    if (perfilEmisor == 'mozo') {
      tagInfo = 'Mozo';
    } else if (numeroMesa != null) {
      tagInfo = 'Mesa $numeroMesa';
    }

    // Color del timestamp según lado
    final Color timestampColor =
        esMio ? Colors.white.withValues(alpha: 0.55) : Colors.grey.shade400;

    return Align(
      alignment: esMio ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment:
              esMio ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // --- Nombre + Tag encima de la burbuja ---
            if (nombreEmisor != null)
              Padding(
                padding: EdgeInsets.only(
                  left: esMio ? 0 : 4,
                  right: esMio ? 4 : 0,
                  bottom: 3,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  // Si es mío, el tag queda a la izquierda del nombre
                  textDirection: esMio ? TextDirection.rtl : TextDirection.ltr,
                  children: [
                    Text(
                      nombreEmisor!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                    if (tagInfo != null) ...[
                      const SizedBox(width: 4),
                      Text(
                        '($tagInfo)',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black.withValues(alpha: 0.4),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

            // --- Burbuja ---
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
              decoration: BoxDecoration(
                color: esMio ? const Color(0xFF5B1718) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(esMio ? 16 : 4),
                  bottomRight: Radius.circular(esMio ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Texto del mensaje (alineado al inicio del texto)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      mensaje,
                      style: TextStyle(
                        fontSize: 15,
                        color: esMio ? Colors.white : const Color(0xFF1A1A1A),
                        height: 1.3,
                      ),
                    ),
                  ),

                  // Fecha + hora al pie derecho
                  if (hora != null || fecha != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (fecha != null)
                          Text(
                            fecha!,
                            style: TextStyle(
                              fontSize: 13,
                              color: timestampColor,
                            ),
                          ),
                        if (fecha != null && hora != null) SizedBox(width: 3),
                        if (hora != null)
                          Text(
                            hora!,
                            style: TextStyle(
                              fontSize: 13,
                              color: timestampColor,
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
