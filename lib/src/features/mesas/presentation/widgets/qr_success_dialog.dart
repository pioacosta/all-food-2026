import 'package:flutter/material.dart';

class QrSuccessDialog extends StatelessWidget {
  const QrSuccessDialog({super.key});



  static const _colorBordo = Color(0xFF8D2628);
  static const _colorBordoOscuro = Color(0xFF6B1C1E);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: _colorBordo,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(24, 36, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ícono de éxito
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Color(0xFF388E3C),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF388E3C).withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Color(0xFFFFFFFF),
                size: 42,
              ),
            ),
            const SizedBox(height: 20),

            // Título
            const Text(
              '¡QR Escaneado!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Elegí una opción para continuar',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 32),

            // Botón: Ver reseñas
            _AccionButton(
              icon: Icons.star_rounded,
              label: 'Ver reseñas',
              descripcion: 'Conocé las opiniones de otros clientes',
              onTap:
                  () => Navigator.of(context).pop(IngresoAccion.verEncuestas),
              backgroundColor: Color(0xFFFFFDD0),
              foregroundColor: _colorBordoOscuro,
              iconColor: _colorBordoOscuro,
            ),
            const SizedBox(height: 14),

            // Botón: Solicitar mesa
            _AccionButton(
              icon: Icons.table_restaurant_rounded,
              label: 'Solicitar mesa',
              descripcion: 'Ingresá a la lista de espera y esperá tu turno',
              onTap:
                  () => Navigator.of(context).pop(IngresoAccion.listaEspera),
              backgroundColor: Color(0xFFFFFDD0),
              foregroundColor: _colorBordoOscuro,
              iconColor: _colorBordoOscuro,
              trailingIcon: Icons.arrow_forward_rounded,
            ),
            const SizedBox(height: 20),

            // Cancelar — bien visible sobre el bordó
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed:
                    () => Navigator.of(context).pop(IngresoAccion.cancelar),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white38, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Botón de acción con descripción ─────────────────────────────────────────

class _AccionButton extends StatelessWidget {
  const _AccionButton({
    required this.icon,
    required this.label,
    required this.descripcion,
    required this.onTap,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.iconColor,
    this.trailingIcon,
  });

  final IconData icon;
  final String label;
  final String descripcion;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color iconColor;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: foregroundColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    descripcion,
                    style: TextStyle(
                      color: foregroundColor.withValues(alpha: 0.75),
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            if (trailingIcon != null) ...[
              const SizedBox(width: 8),
              Icon(trailingIcon, color: iconColor, size: 22),
            ],
          ],
        ),
      ),
    );
  }
}

enum IngresoAccion { listaEspera, verEncuestas, cancelar }
