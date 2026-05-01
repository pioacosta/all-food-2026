import 'package:all_food/src/features/mesas/data/repositories/mesas_repository.dart';
import 'package:all_food/src/features/mesas/presentation/widgets/qr_success_dialog.dart';
import 'package:all_food/src/features/pedidos/presentation/pages/resultados_encuestas_page.dart';
import 'package:all_food/src/shared/errors/app_error_mapper.dart';
import 'package:all_food/src/shared/widgets/logo_spinner.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

enum IngresoQrResultado { listaEspera }

class IngresoListaEsperaQrScannerPage extends StatefulWidget {
  const IngresoListaEsperaQrScannerPage({super.key});

  @override
  State<IngresoListaEsperaQrScannerPage> createState() =>
      _IngresoListaEsperaQrScannerPageState();
}

class _IngresoListaEsperaQrScannerPageState
    extends State<IngresoListaEsperaQrScannerPage> {
  final _controller = MobileScannerController(
    formats: [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  final _repo = MesasRepository();

  bool _procesando = false;
  bool _modalAbierto = false;

  static const _colorPrimario = Color(0xFF8D2628);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_procesando || _modalAbierto) return;

    final raw = capture.barcodes.first.rawValue?.trim() ?? '';
    if (raw.isEmpty) return;

    setState(() => _procesando = true);

    try {
      _repo.validarQrIngresoListaEspera(raw);
      await _controller.stop();
      if (!mounted) return;

      setState(() {
        _procesando = false;
        _modalAbierto = true;
      });

      final accion = await showDialog<IngresoAccion>(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.6),
        builder: (_) => const QrSuccessDialog(),
      );

      if (!mounted) return;

      setState(() {
        _modalAbierto = false;
      });

      if (accion == IngresoAccion.listaEspera) {
        setState(() => _procesando = true);
        await _repo.solicitarMesaClienteActual();
        if (!mounted) return;
        Navigator.of(context).pop(IngresoQrResultado.listaEspera);
        return;
      }

      if (accion == IngresoAccion.verEncuestas) {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ResultadosEncuestasPage()),
        );
      }

      await _controller.start();
    } catch (error) {
      if (!mounted) return;
      final mensaje = AppErrorMapper.toUserMessage(
        error,
        fallbackMessage: 'No se pudo validar el QR de ingreso.',
      );

      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(mensaje),
            backgroundColor: const Color(0xFF992E2E),
          ),
        );
    } finally {
      if (mounted) {
        setState(() => _procesando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _colorPrimario,
        foregroundColor: Colors.white,
        title: const Text(
          'Escanear QR de entrada',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final scanSize = (constraints.maxWidth * 0.7).clamp(220.0, 300.0);
          final scanRect = Rect.fromCenter(
            center: Offset(constraints.maxWidth / 2, constraints.maxHeight / 2),
            width: scanSize,
            height: scanSize,
          );

          return Stack(
            children: [
              MobileScanner(
                controller: _controller,
                scanWindow: scanRect,
                onDetect: _onDetect,
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: _SquareScannerOverlayPainter(scanRect: scanRect),
                ),
              ),
              Center(
                child: Container(
                  width: scanSize,
                  height: scanSize,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.62),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    'Apunta la camara al QR de entrada dentro del recuadro.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ),
              if (_procesando)
                Container(
                  color: Colors.black54,
                  alignment: Alignment.center,
                  child: const LogoSpinner(size: 72, strokeWidth: 4),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _SquareScannerOverlayPainter extends CustomPainter {
  const _SquareScannerOverlayPainter({required this.scanRect});

  final Rect scanRect;

  @override
  void paint(Canvas canvas, Size size) {
    final overlayColor = Colors.black.withValues(alpha: 0.6);
    final path =
        Path()
          ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
          ..addRRect(
            RRect.fromRectAndRadius(scanRect, const Radius.circular(16)),
          )
          ..fillType = PathFillType.evenOdd;

    canvas.drawPath(
      path,
      Paint()
        ..color = overlayColor
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _SquareScannerOverlayPainter oldDelegate) {
    return oldDelegate.scanRect != scanRect;
  }
}
