import 'package:all_food/src/features/auth/widgets/auth_background.dart';
import 'package:all_food/src/features/auth/widgets/auth_card.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({required this.supabaseReady, super.key});

  final bool supabaseReady;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // Clave para validar el formulario completo.
  final _formKey = GlobalKey<FormState>();
  // Controladores de cada campo del registro.
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  var _isLoading = false;

  @override
  void dispose() {
    // Libera recursos al salir de la pantalla.
    _nombreController.dispose();
    _apellidoController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    // Frenar envio si hay errores de validacion local.
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Frenar envio si Supabase no esta configurado/inicializado.
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
      // Crea usuario en Auth y guarda metadatos basicos.
      final response = await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        data: {
          'nombres': _nombreController.text.trim(),
          'apellidos': _apellidoController.text.trim(),
        },
      );

      if (!mounted) return;

      if (response.user == null) {
        _mostrarMensaje('No fue posible crear la cuenta.', esError: true);
        return;
      }

      _mostrarMensaje(
        'Cuenta creada. Revisa tu correo para confirmar el registro si es necesario.',
        esError: false,
      );

      // Vuelve al login para iniciar sesion con la nueva cuenta.
      Navigator.of(context).pop();
    } on AuthException catch (error) {
      _mostrarMensaje(error.message, esError: true);
    } catch (_) {
      _mostrarMensaje(
        'Ocurrió un error inesperado al registrar.',
        esError: true,
      );
    } finally {
      // Siempre quita estado de carga al finalizar.
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _mostrarMensaje(String mensaje, {required bool esError}) {
    // Punto unico para mensajes al usuario.
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
                    'Registrarse',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nombreController,
                    style: const TextStyle(color: Colors.white),
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nombre/s',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) {
                        return 'Debes ingresar los nombres.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _apellidoController,
                    style: const TextStyle(color: Colors.white),
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Apellido/s',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) {
                        return 'Debes ingresar los apellidos.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
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
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _confirmPasswordController,
                    style: const TextStyle(color: Colors.white),
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirmar contraseña',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if ((value ?? '').isEmpty) {
                        return 'Debes confirmar la contraseña.';
                      }
                      if (value != _passwordController.text) {
                        return 'Las contraseñas no coinciden.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _isLoading ? null : _registrar,
                    child:
                        _isLoading
                            // Spinner durante llamada a Supabase.
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Text('Crear cuenta'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed:
                        _isLoading
                            ? null
                            : () {
                              // Vuelve al login manteniendo la navegacion simple.
                              Navigator.of(context).pop();
                            },
                    child: const Text('¿Ya tenés cuenta? Ingresá acá'),
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
