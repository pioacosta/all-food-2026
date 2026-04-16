import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dni_qr_parser.dart';

class DniQrScannerPage extends StatefulWidget {
  const DniQrScannerPage({super.key});

  @override
  State<DniQrScannerPage> createState() => _DniQrScannerPageState();
}

class _DniQrScannerPageState extends State<DniQrScannerPage> {
  final MobileScannerController _controller = MobileScannerController(
    formats: [BarcodeFormat.qrCode, BarcodeFormat.pdf417],
  );

  bool _leyendo = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_leyendo) return;

    final barcode = capture.barcodes.isNotEmpty ? capture.barcodes.first : null;
    final raw = barcode?.rawValue?.trim();

    if (raw == null || raw.isEmpty) return;

    _leyendo = true;

    final data = parsearQrDni(raw);

    if (data.dni == null) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo leer un DNI válido')),
      );

      _leyendo = false;
      return;
    }

    Navigator.of(context).pop(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escanear QR del DNI')),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),

          // 👇 Oscurece todo menos el rectángulo
          Positioned.fill(
            child: CustomPaint(painter: _ScannerOverlayPainter()),
          ),

          // 👇 Borde del rectángulo (más prolijo)
          Center(
            child: Container(
              width: 280,
              height: 160,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),

          const Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Text(
              'Alineá el QR/PDF417 dentro del recuadro',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                shadows: [Shadow(color: Colors.black, blurRadius: 6)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final overlayColor = Colors.black.withValues(alpha: 0.6);

    final paint =
        Paint()
          ..color = overlayColor
          ..style = PaintingStyle.fill;

    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);

    const rectWidth = 280.0;
    const rectHeight = 160.0;

    final centerRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: rectWidth,
      height: rectHeight,
    );

    final path =
        Path()
          ..addRect(fullRect)
          ..addRRect(
            RRect.fromRectAndRadius(centerRect, const Radius.circular(14)),
          )
          ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
