import 'package:flutter/material.dart';
import 'package:all_food/src/shared/widgets/logo_spinner.dart';

// Loader de pantalla completa para estados de espera globales.
class LogoLoader extends StatelessWidget {
  const LogoLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF9e2325),
      body: const Center(child: LogoSpinner(size: 132, strokeWidth: 7)),
    );
  }
}
