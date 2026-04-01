import 'package:all_food/src/features/auth/widgets/auth_background.dart';
import 'package:all_food/src/features/auth/widgets/auth_card.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../home/presentation/pages/home_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    required this.supabaseReady,
    this.initializationMessage,
    super.key,
  });

  final bool supabaseReady;
  final String? initializationMessage;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Clave del formulario para ejecutar validaciones.
  final _formKey = GlobalKey<FormState>();
  // Controladores para leer y limpiar campos de texto.
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  var _isLoading = false;

  @override
  void dispose() {
    // Evita fugas de memoria al cerrar la pantalla.
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _ingresar() async {
    // Valida campos antes de pegarle al backend.
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Bloquea el intento si la app no pudo inicializar Supabase.
    if (!widget.supabaseReady) {
      _mostrarMensaje(
        'No hay conexión a Supabase. Revisa las variables de entorno.',
        esError: true,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Login por email y contraseña usando Supabase Auth.
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (response.user == null) {
        _mostrarMensaje('No fue posible iniciar sesión.', esError: true);
        return;
      }

      // Reemplaza la pantalla actual para que no vuelva al login con atras.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => HomePage(supabaseReady: widget.supabaseReady),
        ),
      );
    } on AuthException catch (error) {
      _mostrarMensaje(error.message, esError: true);
    } catch (_) {
      _mostrarMensaje(
        'Ocurrió un error inesperado al ingresar.',
        esError: true,
      );
    } finally {
      // Siempre re-habilita botones al terminar.
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _mostrarMensaje(String mensaje, {required bool esError}) {
    // Centraliza mensajes de error/exito en un mismo estilo visual.
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
    return AuthBackground(
      child: Center(
        child: AuthCard(
          children: [
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'All Food',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Inicio de sesión',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  if (widget.initializationMessage != null) ...[
                    const SizedBox(height: 16),
                    MaterialBanner(
                      backgroundColor: const Color(0xFF244A8F),
                      content: Text(
                        widget.initializationMessage!,
                        style: const TextStyle(color: Colors.white),
                      ),
                      actions: const [SizedBox.shrink()],
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final email = value?.trim() ?? '';
                      if (email.isEmpty) {
                        return 'Debes ingresar un correo electrónico.';
                      }
                      final pattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                      if (!pattern.hasMatch(email)) {
                        return 'Correo electrónico inválido.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _passwordController,
                    style: const TextStyle(color: Colors.white),
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Contraseña',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final password = value ?? '';
                      if (password.isEmpty) {
                        return 'Debes ingresar una contraseña.';
                      }
                      if (password.length < 6) {
                        return 'La contraseña debe tener al menos 6 caracteres.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _isLoading ? null : _ingresar,
                    child:
                        _isLoading
                            // Indicador visual en esperas de red.
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Text('Ingresar'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed:
                        _isLoading
                            ? null
                            : () {
                              // Navega al registro para crear nueva cuenta.
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder:
                                      (_) => RegisterPage(
                                        supabaseReady: widget.supabaseReady,
                                      ),
                                ),
                              );
                            },
                    child: const Text('Crear cuenta'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
