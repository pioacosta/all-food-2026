import 'package:all_food/src/features/mesas/presentation/pages/consulta_mozo_page.dart';
import 'package:flutter/material.dart';

class MesaClienteAccesoPage extends StatelessWidget {
  const MesaClienteAccesoPage({required this.mesa, super.key});

  final Map<String, dynamic> mesa;

  @override
  Widget build(BuildContext context) {
    final numeroMesa = mesa['numero'];

    return Scaffold(
      appBar: AppBar(title: const Text('Mesa validada')),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF5B1718), Color(0xFF7A2021)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  color: const Color(0xFF8B1A1A),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text(
                          'Acceso habilitado por QR de mesa',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Mesa $numeroMesa',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _AccesoCard(
                  titulo: 'Ver carta de platos',
                  detalle:
                      'Productos con fotos, descripcion, precio y tiempo estimado.',
                  icono: Icons.restaurant_menu,
                  onTap:
                      () => Navigator.pushNamed(
                        context,
                        '/carta-cliente',
                        arguments: 'plato',
                      ),
                ),
                const SizedBox(height: 10),
                _AccesoCard(
                  titulo: 'Ver carta de bebidas',
                  detalle:
                      'Bebidas con fotos, descripcion, precio y tiempo estimado.',
                  icono: Icons.local_bar,
                  onTap:
                      () => Navigator.pushNamed(
                        context,
                        '/carta-cliente',
                        arguments: 'bebida',
                      ),
                ),
                const SizedBox(height: 10),
                _AccesoCard(
                  titulo: 'Consulta al mozo',
                  detalle:
                      'Envia consultas rapidas al mozo con fecha y hora de registro.',
                  icono: Icons.support_agent,
                  onTap:
                      () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder:
                              (_) => ConsultaMozoPage(
                                mesaId: mesa['id'] as String,
                                numeroMesa: (mesa['numero'] as num).toInt(),
                              ),
                        ),
                      ),
                ),
                const SizedBox(height: 10),
                const _AccesoCard(
                  titulo: 'Estado de pedido y juegos',
                  detalle:
                      'Disponible cuando se complete el flujo de pedido y descuentos.',
                  icono: Icons.pending_actions,
                  habilitado: false,
                ),
                const SizedBox(height: 10),
                const _AccesoCard(
                  titulo: 'Encuesta y pedir cuenta',
                  detalle:
                      'Se habilita despues de la entrega del pedido y cierre de mesa.',
                  icono: Icons.receipt_long,
                  habilitado: false,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AccesoCard extends StatelessWidget {
  const _AccesoCard({
    required this.titulo,
    required this.detalle,
    required this.icono,
    this.habilitado = true,
    this.onTap,
  });

  final String titulo;
  final String detalle;
  final IconData icono;
  final bool habilitado;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorTitulo = habilitado ? Colors.white : Colors.white60;

    return InkWell(
      onTap: habilitado ? onTap : null,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        decoration: BoxDecoration(
          color: const Color(0xFF8B1A1A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icono, color: colorTitulo),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: TextStyle(
                        color: colorTitulo,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      detalle,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
