import 'package:all_food/src/shared/theme/app_ui.dart';
import 'package:flutter/material.dart';

class HeroMesaCard extends StatelessWidget {
  const HeroMesaCard({super.key, required this.numeroMesa, required this.estado});

  final int numeroMesa;
  final String? estado;

  String get _estadoTexto {
    switch (estado) {
      case 'confirmado_mozo':
        return 'Confirmado por el mozo';
      case 'en_preparacion':
        return 'En preparación';
      case 'listo_para_entrega':
        return 'Listo para entregar';
      case 'entregado_por_mozo':
        return 'Entregado por el mozo';
      case 'recibido_cliente':
        return 'Recibido';
      case 'cuenta_solicitada':
        return 'Cuenta solicitada';
      case 'pago_pendiente_confirmacion':
        return 'Pago pendiente';
      default:
        return 'Sin pedido activo';
    }
  }

  bool get _tienePedido => estado != null && estado!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
      decoration: BoxDecoration(
        color: const Color(0xFF5C1F1F),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Stack(
        children: [
          // ── Círculos decorativos ────────────────────────────────────
          _circulo(right: -16, bottom: -16, size: 90, alpha: 0.040),
          _circulo(left: -18, top: -18, size: 65, alpha: 0.030),
          _circulo(right: 50, top: -32, size: 70, alpha: 0.025),
          _circulo(left: 30, bottom: -20, size: 45, alpha: 0.020),
          _circulo(right: -30, top: 20, size: 50, alpha: 0.030),
          _circulo(right: 10, bottom: 30, size: 30, alpha: 0.020),

          // ── Watermark número ────────────────────────────────────────
          Positioned(
            right: -8,
            bottom: -20,
            child: Text(
              '$numeroMesa',
              style: TextStyle(
                fontFamily: 'serif',
                color: Colors.white.withValues(alpha: 0.055),
                fontSize: 160,
                fontWeight: FontWeight.w900,
                height: 1,
                letterSpacing: -4,
              ),
            ),
          ),

          // ── Contenido ───────────────────────────────────────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Mesa $numeroMesa',
                style: const TextStyle(
                  fontFamily: 'serif',
                  color: AppUi.texto,
                  fontSize: 50,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              Container(
                width: 32,
                height: 1.5,
                margin: const EdgeInsets.symmetric(vertical: 10),
                color: Colors.white.withValues(alpha: 0.15),
              ),
              Text(
                'ESTADO',
                style: TextStyle(
                  color: AppUi.textoSecundario.withValues(alpha: 0.45),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _estadoTexto,
                style: TextStyle(
                  color:
                      _tienePedido
                          ? const Color(0xFFE8A87C)
                          : AppUi.textoSecundario.withValues(alpha: 0.35),
                  fontSize: 18,
                  fontWeight: _tienePedido ? FontWeight.w600 : FontWeight.w400,
                  fontStyle: _tienePedido ? FontStyle.normal : FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper para no repetir código
  Widget _circulo({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required double size,
    required double alpha,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: alpha),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}