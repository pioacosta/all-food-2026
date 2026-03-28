import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({required this.supabaseReady, super.key});

  final bool supabaseReady;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  var _cerrandoSesion = false;

  Future<void> _cerrarSesion() async {
    // Evita dobles taps que disparen logout multiple.
    if (_cerrandoSesion) return;

    setState(() {
      _cerrandoSesion = true;
    });

    try {
      if (widget.supabaseReady) {
        // Cierra sesion del usuario en Supabase Auth.
        await Supabase.instance.client.auth.signOut();
      }

      if (!mounted) return;
      // Vuelve al inicio de navegacion (SessionGate llevara a login).
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on AuthException catch (error) {
      _mostrarMensaje(error.message, esError: true);
    } catch (_) {
      _mostrarMensaje('No fue posible cerrar sesión.', esError: true);
    } finally {
      if (mounted) {
        setState(() {
          _cerrandoSesion = false;
        });
      }
    }
  }

  void _mostrarMensaje(String mensaje, {required bool esError}) {
    // Mensajes reutilizables para errores/informacion.
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor:
              esError ? const Color(0xFF992E2E) : const Color(0xFF2D6A4F),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Food'),
        actions: [
          TextButton(
            onPressed: _cerrandoSesion ? null : _cerrarSesion,
            child:
                _cerrandoSesion
                    ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Text('Cerrar sesión'),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A1931), Color(0xFF102A5C)],
          ),
        ),
        child: const SafeArea(
          child: Center(
            child: Text(
              'Inicio (vacío)\n\nBase lista para comenzar con los módulos de All Food.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
