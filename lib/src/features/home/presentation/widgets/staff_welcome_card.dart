import 'package:all_food/src/shared/theme/app_ui.dart';
import 'package:flutter/material.dart';

class StaffWelcomeCard extends StatelessWidget {
  const StaffWelcomeCard({
    super.key,
    required this.nombre,
    required this.apellido,
    required this.email,
    required this.perfil,
  });

  final String? nombre;
  final String? apellido;
  final String? email;
  final String? perfil;

  String _labelPerfil(String? p) => switch (p) {
    'dueno' => 'Dueño',
    'supervisor' => 'Supervisor',
    'metre' => 'Metre',
    'mozo' => 'Mozo',
    'cocinero' => 'Cocinero',
    'cantinero' => 'Cantinero',
    _ => p ?? '',
  };

  @override
  Widget build(BuildContext context) {
    final nombreCompleto = [
      nombre,
      apellido,
    ].where((s) => s != null && s.isNotEmpty).join(' ');

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
      decoration: AppUi.panelDecoracion(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Hola de nuevo',
                style: TextStyle(
                  fontSize: 16,
                  color: AppUi.textoSecundario,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppUi.acento,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppUi.acento.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  _labelPerfil(perfil),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF4A0E10),
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            nombreCompleto.isNotEmpty ? nombreCompleto : 'Sin nombre',
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w800,
              color: AppUi.texto,
              letterSpacing: -0.4,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          if (email != null && email!.isNotEmpty)
            Text(
              email!,
              style: const TextStyle(
                fontSize: 16,
                color: AppUi.textoSecundario,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}
