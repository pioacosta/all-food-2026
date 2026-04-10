import 'package:flutter/material.dart';

// Spinner reutilizable con el logo de la app en el centro.
class LogoSpinner extends StatelessWidget {
  const LogoSpinner({
    this.size = 64,
    this.strokeWidth = 4,
    this.logoScale = 0.62,
    super.key,
  });

  final double size;
  final double strokeWidth;
  final double logoScale;

  @override
  Widget build(BuildContext context) {
    // Superpone indicador de progreso con imagen circular del logo.
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: strokeWidth,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          Container(
            width: size * logoScale,
            height: size * logoScale,
            decoration: const BoxDecoration(
              color: Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
            ),
          ),
        ],
      ),
    );
  }
}
