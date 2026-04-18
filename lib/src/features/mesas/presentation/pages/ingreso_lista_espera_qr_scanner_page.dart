import 'package:all_food/src/features/mesas/data/repositories/mesas_repository.dart';
import 'package:all_food/src/shared/errors/app_error_mapper.dart';
import 'package:all_food/src/shared/widgets/logo_spinner.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

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
      await _repo.solicitarMesaClienteActualPorQrIngreso(raw);
      if (!mounted) return;

      Navigator.of(context).pop(true);
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
      appBar: AppBar(title: const Text('Escanear QR de entrada')),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.62),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Escaneá el QR de entrada del local para anotarte en lista de espera.',
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
      ),
    );
  }
}
