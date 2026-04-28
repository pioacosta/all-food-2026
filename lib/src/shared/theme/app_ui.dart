import 'package:flutter/material.dart';

class AppUi {
  static const Color fondoSuperior = Color(0xFF4A0E10);
  static const Color fondoMedio = Color(0xFF7A2021);
  static const Color fondoInferior = Color(0xFFA12D22);
  static const Color panel = Color(0xFF8D2628);
  static const Color panelClaro = Color(0xFFA6332E);
  static const Color acento = Color(0xFFFFC857);
  static const Color exito = Color(0xFF2D6A4F);
  static const Color error = Color(0xFF992E2E);
  static const Color texto = Colors.white;
  static const Color textoSecundario = Color(0xFFEBD8D3);

  static const LinearGradient fondoPrincipal = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [fondoSuperior, fondoMedio, fondoInferior],
    stops: [0.0, 0.55, 1.0],
  );

  static BoxDecoration panelDecoracion({double radius = 18}) {
    return BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [panelClaro, panel],
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.white24),
      boxShadow: const [
        BoxShadow(
          color: Color(0x40000000),
          blurRadius: 16,
          offset: Offset(0, 8),
        ),
      ],
    );
  }
}

