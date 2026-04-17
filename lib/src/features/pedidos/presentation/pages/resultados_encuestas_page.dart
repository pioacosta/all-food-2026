import 'dart:math' as math;

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
  final _pageController = PageController();

  bool _cargando = true;
  int _paginaActual = 0;
  Map<String, dynamic> _resumen = const {};
  List<Map<String, dynamic>> _serie = const [];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final resumen = await _repo.getResumenEncuestas();
      final serie = await _repo.getSerieSatisfaccionDiaria(maxDias: 7);
      if (!mounted) return;
      setState(() {
        _resumen = resumen;
        _serie = serie;
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _cargando = false);
    }
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
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Column(
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
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(3, (i) {
                                  final activo = _paginaActual == i;
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 3,
                                    ),
                                    height: 8,
                                    width: activo ? 20 : 8,
                                    decoration: BoxDecoration(
                                      color:
                                          activo
                                              ? const Color(0xFFFACC15)
                                              : Colors.white38,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: PageView(
                            controller: _pageController,
                            onPageChanged: (i) {
                              setState(() => _paginaActual = i);
                            },
                            children: [
                              _TarjetaGrafico(
                                titulo: 'Gráfico de barras - Promedios',
                                child: _GraficoBarrasPromedios(
                                  comida: promedioComida,
                                  servicio: promedioServicio,
                                ),
                              ),
                              _TarjetaGrafico(
                                titulo: 'Gráfico de torta - Recomendación',
                                child: _GraficoTortaRecomendacion(
                                  recomendacion: recomendacion,
                                ),
                              ),
                              _TarjetaGrafico(
                                titulo: 'Gráfico lineal - Tendencia diaria',
                                child: _GraficoLinealTendencia(serie: _serie),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
        ),
      ),
    );
  }
}

class _TarjetaGrafico extends StatelessWidget {
  const _TarjetaGrafico({required this.titulo, required this.child});

  final String titulo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
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
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _GraficoBarrasPromedios extends StatelessWidget {
  const _GraficoBarrasPromedios({required this.comida, required this.servicio});

  final double comida;
  final double servicio;

  @override
  Widget build(BuildContext context) {
    final comidaPct = (comida / 5).clamp(0.0, 1.0);
    final servicioPct = (servicio / 5).clamp(0.0, 1.0);

    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _BarraVertical(
                etiqueta: 'Comida',
                valor: comida,
                porcentaje: comidaPct,
                color: const Color(0xFF4ADE80),
              ),
              _BarraVertical(
                etiqueta: 'Servicio',
                valor: servicio,
                porcentaje: servicioPct,
                color: const Color(0xFF38BDF8),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text('Escala de 1 a 5', style: TextStyle(color: Colors.white70)),
      ],
    );
  }
}

class _BarraVertical extends StatelessWidget {
  const _BarraVertical({
    required this.etiqueta,
    required this.valor,
    required this.porcentaje,
    required this.color,
  });

  final String etiqueta;
  final double valor;
  final double porcentaje;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            valor.toStringAsFixed(2),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: porcentaje,
                child: Container(
                  width: 58,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white30),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(etiqueta, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}

class _GraficoTortaRecomendacion extends StatelessWidget {
  const _GraficoTortaRecomendacion({required this.recomendacion});

  final double recomendacion;

  @override
  Widget build(BuildContext context) {
    final si = recomendacion.clamp(0.0, 100.0);
    final no = (100.0 - si).clamp(0.0, 100.0);

    return Column(
      children: [
        Expanded(
          child: Center(
            child: SizedBox(
              width: 220,
              height: 220,
              child: CustomPaint(painter: _PiePainter(siPorcentaje: si)),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const _Leyenda(color: Color(0xFFFACC15), texto: 'Sí recomienda'),
            const SizedBox(width: 12),
            _Leyenda(color: const Color(0xFF52525B), texto: 'No recomienda'),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Sí: ${si.toStringAsFixed(1)}%  |  No: ${no.toStringAsFixed(1)}%',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _PiePainter extends CustomPainter {
  _PiePainter({required this.siPorcentaje});

  final double siPorcentaje;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final paintSi = Paint()..color = const Color(0xFFFACC15);
    final paintNo = Paint()..color = const Color(0xFF52525B);

    final sweepSi = 2 * math.pi * (siPorcentaje / 100.0);

    canvas.drawArc(rect, -math.pi / 2, sweepSi, true, paintSi);
    canvas.drawArc(
      rect,
      -math.pi / 2 + sweepSi,
      2 * math.pi - sweepSi,
      true,
      paintNo,
    );

    final donut = Paint()..color = const Color(0xFF6E1E20);
    canvas.drawCircle(center, radius * 0.45, donut);
  }

  @override
  bool shouldRepaint(covariant _PiePainter oldDelegate) {
    return oldDelegate.siPorcentaje != siPorcentaje;
  }
}

class _Leyenda extends StatelessWidget {
  const _Leyenda({required this.color, required this.texto});

  final Color color;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(texto, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }
}

class _GraficoLinealTendencia extends StatelessWidget {
  const _GraficoLinealTendencia({required this.serie});

  final List<Map<String, dynamic>> serie;

  @override
  Widget build(BuildContext context) {
    if (serie.isEmpty) {
      return const Center(
        child: Text(
          'No hay datos suficientes para mostrar tendencia.',
          style: TextStyle(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: CustomPaint(
            painter: _LineasPainter(serie: serie),
            child: const SizedBox.expand(),
          ),
        ),
        const SizedBox(height: 8),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Leyenda(color: Color(0xFF4ADE80), texto: 'Comida'),
            SizedBox(width: 12),
            _Leyenda(color: Color(0xFF38BDF8), texto: 'Servicio'),
          ],
        ),
      ],
    );
  }
}

class _LineasPainter extends CustomPainter {
  _LineasPainter({required this.serie});

  final List<Map<String, dynamic>> serie;

  @override
  void paint(Canvas canvas, Size size) {
    final axisPaint =
        Paint()
          ..color = Colors.white54
          ..strokeWidth = 1;

    final left = 18.0;
    final top = 10.0;
    final bottom = size.height - 24;
    final right = size.width - 10;

    canvas.drawLine(Offset(left, top), Offset(left, bottom), axisPaint);
    canvas.drawLine(Offset(left, bottom), Offset(right, bottom), axisPaint);

    if (serie.length == 1) {
      final y = _yFromScore(
        ((serie.first['comida'] as num?) ?? 0).toDouble(),
        top,
        bottom,
      );
      final p = Paint()..color = const Color(0xFF4ADE80);
      canvas.drawCircle(Offset((left + right) / 2, y), 4, p);
      return;
    }

    final comidaPath = Path();
    final servicioPath = Path();
    final comidaPaint =
        Paint()
          ..color = const Color(0xFF4ADE80)
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke;
    final servicioPaint =
        Paint()
          ..color = const Color(0xFF38BDF8)
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke;

    for (var i = 0; i < serie.length; i++) {
      final t = i / (serie.length - 1);
      final x = left + (right - left) * t;
      final comida = ((serie[i]['comida'] as num?) ?? 0).toDouble();
      final servicio = ((serie[i]['servicio'] as num?) ?? 0).toDouble();
      final yComida = _yFromScore(comida, top, bottom);
      final yServicio = _yFromScore(servicio, top, bottom);

      if (i == 0) {
        comidaPath.moveTo(x, yComida);
        servicioPath.moveTo(x, yServicio);
      } else {
        comidaPath.lineTo(x, yComida);
        servicioPath.lineTo(x, yServicio);
      }

      canvas.drawCircle(
        Offset(x, yComida),
        3,
        Paint()..color = const Color(0xFF4ADE80),
      );
      canvas.drawCircle(
        Offset(x, yServicio),
        3,
        Paint()..color = const Color(0xFF38BDF8),
      );
    }

    canvas.drawPath(comidaPath, comidaPaint);
    canvas.drawPath(servicioPath, servicioPaint);
  }

  double _yFromScore(double score, double top, double bottom) {
    final clamped = score.clamp(0.0, 5.0);
    final pct = clamped / 5.0;
    return bottom - (bottom - top) * pct;
  }

  @override
  bool shouldRepaint(covariant _LineasPainter oldDelegate) {
    return oldDelegate.serie != serie;
  }
}
