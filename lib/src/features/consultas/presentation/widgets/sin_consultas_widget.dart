import 'package:flutter/material.dart';

// ─── Empty state ──────────────────────────────────────────────────────────────
class SinConsultasWidget extends StatelessWidget {
  const SinConsultasWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.coffee_outlined, size: 64, color: Colors.white24),
          SizedBox(height: 20),
          Text(
            'Todo tranquilo',
            style: TextStyle(
              fontFamily: 'ArchivoBlack',
              fontSize: 24,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'No hay consultas activas en este momento.',
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
