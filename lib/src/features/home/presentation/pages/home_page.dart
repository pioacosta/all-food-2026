import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/widgets/logo_spinner.dart';

import '../../../auth/presentation/pages/login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({required this.supabaseReady, super.key});

  final bool supabaseReady;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  var _cerrandoSesion = false;
  bool _cargandoPerfil = true;
  String? _perfil;

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  Future<void> _cargarPerfil() async {
    if (!widget.supabaseReady) {
      setState(() {
        _perfil = null;
        _cargandoPerfil = false;
      });
      return;
    }

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        if (!mounted) return;
        setState(() {
          _perfil = null;
          _cargandoPerfil = false;
        });
        return;
      }

      final data =
          await supabase
              .from('perfiles')
              .select('perfil')
              .eq('id', userId)
              .single();

      if (!mounted) return;
      setState(() {
        _perfil = data['perfil'] as String?;
        _cargandoPerfil = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _perfil = null;
        _cargandoPerfil = false;
      });
    }
  }

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
      // Limpia la navegacion y vuelve al ingreso con confirmacion visual.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder:
              (_) => LoginPage(
                supabaseReady: widget.supabaseReady,
                successMessage: 'Sesión cerrada correctamente.',
              ),
        ),
        (route) => false,
      );
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
    final puedeCrearEmpleados = _perfil == 'dueno' || _perfil == 'supervisor';

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
            colors: [Color(0xFF5B1718), Color(0xFF7A2021)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child:
                _cargandoPerfil
                    ? const LogoSpinner(size: 90, strokeWidth: 6)
                    : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/crear-plato');
                          },
                          child: const Text('Crear plato'),
                        ),
                        const SizedBox(height: 12),
                        if (puedeCrearEmpleados)
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/alta-empleado');
                            },
                            child: const Text('Alta de empleados'),
                          ),
                      ],
                    ),
          ),
        ),
      ),
    );
  }
}
