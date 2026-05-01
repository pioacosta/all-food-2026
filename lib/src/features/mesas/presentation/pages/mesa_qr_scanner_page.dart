import 'package:all_food/src/features/mesas/data/repositories/mesas_repository.dart';
import 'package:all_food/src/features/mesas/presentation/pages/mesa_cliente_acceso_page.dart';
import 'package:all_food/src/shared/errors/app_error_mapper.dart';
import 'package:all_food/src/shared/widgets/logo_spinner.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class MesaQrScannerPage extends StatefulWidget {
  const MesaQrScannerPage({super.key});

  @override
  State<MesaQrScannerPage> createState() => _MesaQrScannerPageState();
}

class _MesaQrScannerPageState extends State<MesaQrScannerPage> {
  final _controller = MobileScannerController(
    formats: [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  final _repo = MesasRepository();

  bool _procesando = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_procesando) return;

    final raw = capture.barcodes.first.rawValue?.trim() ?? '';
    if (raw.isEmpty) return;

    setState(() => _procesando = true);

    try {
      final mesa = await _repo.validarAccesoClientePorQrMesa(raw);
      if (!mounted) return;

      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => MesaClienteAccesoPage(mesa: mesa)),
      );
    } catch (error) {
      if (!mounted) return;
      final mensaje = AppErrorMapper.toUserMessage(
        error,
        fallbackMessage: 'No se pudo validar el QR de la mesa.',
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
      appBar: AppBar(title: const Text('Escanear QR de mesa')),
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
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Escanea el QR de tu mesa dentro del recuadro.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white),
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
