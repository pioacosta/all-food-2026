import 'package:flutter/material.dart';
import 'package:all_food/src/shared/theme/app_ui.dart';

// Scaffold base reutilizable para pantallas de autenticacion.
class AuthBackground extends StatelessWidget {
  final Widget child;
  final Widget? floatingActionButton;

  const AuthBackground({
    super.key,
    required this.child,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    // Aplica fondo degradado y respeta zonas seguras del dispositivo.
    final teclado = MediaQuery.of(context).viewInsets.bottom;
    return Scaffold(
      floatingActionButton: floatingActionButton,
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(gradient: AppUi.fondoPrincipal),
          ),
          Positioned(
            top: -80,
            right: -50,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppUi.acento.withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            bottom: -90,
            left: -70,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          SafeArea(
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 170),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(bottom: teclado),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
