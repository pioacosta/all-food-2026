import 'package:all_food/src/features/mesas/data/repositories/mesas_repository.dart';
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

      final accion = await showModalBottomSheet<_IngresoAccion>(
        context: context,
        backgroundColor: const Color(0xFF8D2628),
        builder:
            (_) => SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'QR de entrada validado',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () {
                        Navigator.of(context).pop(_IngresoAccion.listaEspera);
                      },
                      child: const Text('Anotarme en lista de espera'),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.tonal(
                      onPressed: () {
                        Navigator.of(context).pop(_IngresoAccion.verEncuestas);
                      },
                      child: const Text('Ver resultados de encuestas'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop(_IngresoAccion.cancelar);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white70),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ],
                ),
              ),
            ),
      );

      if (!mounted) return;

      setState(() {
        _modalAbierto = false;
      });

      if (accion == _IngresoAccion.listaEspera) {
        setState(() => _procesando = true);
        await _repo.solicitarMesaClienteActual();
        if (!mounted) return;
        Navigator.of(context).pop(IngresoQrResultado.listaEspera);
        return;
      }

      if (accion == _IngresoAccion.verEncuestas) {
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
                'Escaneá el QR de entrada para anotarte en lista de espera o ver encuestas previas.',
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

enum _IngresoAccion { listaEspera, verEncuestas, cancelar }
