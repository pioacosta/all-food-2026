import 'package:all_food/src/features/pedidos/data/repositories/pedidos_repository.dart';
import 'package:all_food/src/shared/widgets/logo_spinner.dart';
import 'package:flutter/material.dart';

class ResultadosEncuestasPage extends StatefulWidget {
  const ResultadosEncuestasPage({super.key});

  @override
  State<ResultadosEncuestasPage> createState() =>
      _ResultadosEncuestasPageState();
}

class _ResultadosEncuestasPageState extends State<ResultadosEncuestasPage> {
  final _repo = PedidosRepository();

  bool _cargando = true;
  Map<String, dynamic> _resumen = const {};

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final data = await _repo.getResumenEncuestas();
    if (!mounted) return;
    setState(() {
      _resumen = data;
      _cargando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cantidad = (_resumen['cantidad'] as num?)?.toInt() ?? 0;
    final promedioComida =
        ((_resumen['promedioComida'] as num?) ?? 0).toDouble();
    final promedioServicio =
        ((_resumen['promedioServicio'] as num?) ?? 0).toDouble();
    final recomendacion =
        ((_resumen['porcentajeRecomendacion'] as num?) ?? 0).toDouble();

    return Scaffold(
      appBar: AppBar(title: const Text('Resultados de encuestas')),
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
          child:
              _cargando
                  ? const Center(child: LogoSpinner(size: 70, strokeWidth: 4))
                  : Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Encuestas respondidas: $cantidad',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _BarraResultado(
                          titulo: 'Promedio comida',
                          valor: promedioComida,
                          maximo: 5,
                          color: const Color(0xFF4ADE80),
                          textoValor: promedioComida.toStringAsFixed(2),
                        ),
                        const SizedBox(height: 10),
                        _BarraResultado(
                          titulo: 'Promedio servicio',
                          valor: promedioServicio,
                          maximo: 5,
                          color: const Color(0xFF38BDF8),
                          textoValor: promedioServicio.toStringAsFixed(2),
                        ),
                        const SizedBox(height: 10),
                        _BarraResultado(
                          titulo: 'Recomendación',
                          valor: recomendacion,
                          maximo: 100,
                          color: const Color(0xFFFACC15),
                          textoValor: '${recomendacion.toStringAsFixed(1)}%',
                        ),
                      ],
                    ),
                  ),
        ),
      ),
    );
  }
}

class _BarraResultado extends StatelessWidget {
  const _BarraResultado({
    required this.titulo,
    required this.valor,
    required this.maximo,
    required this.color,
    required this.textoValor,
  });

  final String titulo;
  final double valor;
  final double maximo;
  final Color color;
  final String textoValor;

  @override
  Widget build(BuildContext context) {
    final porcentaje =
        maximo == 0 ? 0.0 : (valor / maximo).clamp(0.0, 1.0).toDouble();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(textoValor, style: const TextStyle(color: Colors.white)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 12,
              value: porcentaje,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}
