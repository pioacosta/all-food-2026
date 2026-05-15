import 'package:flutter/material.dart';

// ─── Empty state ──────────────────────────────────────────────────────────────
class SinConsultasWidget extends StatelessWidget {
  const SinConsultasWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.coffee_outlined, size: 92, color: Colors.white30),
            SizedBox(height: 24),
            Text(
              'Todo tranquilo',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'ArchivoBlack',
                fontSize: 38,
                color: Colors.white,
                height: 1.05,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'No hay consultas activas en este momento.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 19,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
