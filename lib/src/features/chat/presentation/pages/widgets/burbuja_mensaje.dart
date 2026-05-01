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
    String? etiquetaEmisor;
    if (perfilEmisor == 'mozo') {
      etiquetaEmisor = nombreEmisor;
    } else if (numeroMesa != null) {
      etiquetaEmisor = 'Mesa $numeroMesa';
    } else {
      etiquetaEmisor = nombreEmisor;
    }

    final Color timestampColor =
        esMio ? Colors.white.withValues(alpha: 0.65) : const Color(0xFFD4B9BC);

    return Align(
      alignment: esMio ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        child: Column(
          crossAxisAlignment:
              esMio ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (etiquetaEmisor != null)
              Padding(
                padding: EdgeInsets.only(
                  left: esMio ? 0 : 4,
                  right: esMio ? 4 : 0,
                  bottom: 3,
                ),
                child: Text(
                  etiquetaEmisor,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFFFE2E2),
                    height: 1.1,
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
              decoration: BoxDecoration(
                color:
                    esMio ? const Color(0xFF6D1B1D) : const Color(0xFF3A242A),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(esMio ? 16 : 4),
                  bottomRight: Radius.circular(esMio ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    mensaje,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: esMio ? Colors.white : const Color(0xFFFFECEC),
                      height: 1.25,
                    ),
                  ),
                  if (hora != null || fecha != null) ...[
                    const SizedBox(height: 3),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (fecha != null)
                            Text(
                              fecha!,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: timestampColor,
                                height: 1.0,
                              ),
                            ),
                          if (fecha != null && hora != null)
                            const SizedBox(width: 3),
                          if (hora != null)
                            Text(
                              hora!,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: timestampColor,
                                height: 1.0,
                              ),
                            ),
                        ],
                      ),
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
