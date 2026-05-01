import 'package:all_food/src/shared/widgets/logo_spinner.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Resultado del escaneo del QR de propina.
/// Retorna el porcentaje elegido (0, 5, 10, 15 o 20).
class PropinaScannerPage extends StatefulWidget {
  const PropinaScannerPage({super.key});

  @override
  State<PropinaScannerPage> createState() => _PropinaScannerPageState();
}

class _PropinaScannerPageState extends State<PropinaScannerPage> {
  final _controller = MobileScannerController(
    formats: [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

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

    // Formato esperado: "PROPINA:20", "PROPINA:15", etc.
    if (!raw.startsWith('PROPINA:')) {
      _mostrarError('QR invalido. Usa el QR de propina correspondiente.');
      return;
    }

    final partes = raw.split(':');
    final porcentaje = int.tryParse(partes.length > 1 ? partes[1] : '');

    if (porcentaje == null || ![0, 5, 10, 15, 20].contains(porcentaje)) {
      _mostrarError('El QR no contiene un porcentaje de propina valido.');
      return;
    }

    setState(() => _procesando = true);

    await Future<void>.delayed(const Duration(milliseconds: 400));

    if (!mounted) return;
    Navigator.of(context).pop(porcentaje);
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: const Color(0xFF992E2E),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escanear QR de propina')),
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
                    'Apunta la camara al QR de propina dentro del recuadro.',
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
