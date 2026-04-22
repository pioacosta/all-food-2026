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
    'metre' => 'Maître',
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
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5DC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF3D1F1F).withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Saludo + badge en la misma fila
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '¡Hola de nuevo!',
                style: TextStyle(
                  fontSize: 16,
                  color: const Color(0xFF3D1F1F),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B1C1E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF6B1C1E).withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  _labelPerfil(perfil),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombreCompleto.isNotEmpty ? nombreCompleto : 'Sin nombre',
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF3D1F1F),
                        letterSpacing: -0.4,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (email != null && email!.isNotEmpty)
                      Text(
                        email!,
                        style: TextStyle(
                          fontSize: 16,
                          color: const Color(
                            0xFF3D1F1F,
                          ),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
