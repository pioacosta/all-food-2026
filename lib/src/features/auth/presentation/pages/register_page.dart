import 'dart:io';
import 'package:all_food/src/features/auth/widgets/auth_background.dart';
import 'package:all_food/src/features/auth/widgets/auth_card.dart';
import 'package:all_food/src/shared/widgets/logo_spinner.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  final _dniController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  File? _foto;

  var _isLoading = false;

  @override
  void dispose() {
    // Libera recursos al salir de la pantalla.
    _nombreController.dispose();
    _apellidoController.dispose();
    _dniController.dispose();
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

    if (_foto == null) {
      _mostrarMensaje('Debes tomar una foto.', esError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final supabase = Supabase.instance.client;

      // paso 1 crear usuario en auth.
      final response = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      final user = response.user;

      if (user == null) {
        _mostrarMensaje('No fue posible crear la cuenta.', esError: true);
        return;
      }

      final userId = user.id;

      // paso 2 subir imagen a storage
      final fileName = '$userId-${DateTime.now().millisecondsSinceEpoch}.jpg';

      await supabase.storage.from('avatares').upload(fileName, _foto!);

      // paso 3 obtener URL publica
      final fotoUrl = supabase.storage.from('avatares').getPublicUrl(fileName);

      // paso 4 insetar en tabla perfiles
      await supabase.from('perfiles').insert({
        'id': userId,
        'nombres': _nombreController.text.trim(),
        'apellidos': _apellidoController.text.trim(),
        'dni': _dniController.text.trim(),
        'correo': _emailController.text.trim(),
        'perfil': 'cliente_registrado',
        'estado_registro': 'pendiente_aprobacion',
        'foto_url': fotoUrl,
        'habilitado': false,
      });

      _mostrarMensaje(
        'Registro exitoso. Esperando aprobación.',
        esError: false,
      );

      await Supabase.instance.client.auth.signOut();

      if (!mounted) return;

      Navigator.of(context).pop();
    } on AuthException catch (error) {
      _mostrarMensaje(error.message, esError: true);
    } catch (e) {
      _mostrarMensaje(
        'Ocurrió un error inesperado al registrar. $e',
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
                      fontFamily: 'ArchivoBlack',
                      fontSize: 34,
                      color: Colors.white,
                      letterSpacing: -2,
                      height: 1,
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
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _dniController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'DNI',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) {
                        return 'Debes ingresar el DNI.';
                      }
                      if (!RegExp(r'^\d+$').hasMatch(text)) {
                        return 'El DNI debe ser numérico.';
                      }
                      if (text.length < 7) {
                        return 'DNI inválido.';
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
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      final picker = ImagePicker();
                      final picked = await picker.pickImage(
                        source: ImageSource.camera,
                      );

                      if (picked != null) {
                        setState(() {
                          _foto = File(picked.path);
                        });
                      }
                    },
                    child: const Text('Tomar foto'),
                  ),
                  const SizedBox(height: 10),

                  // PREVIEW DE LA FOTO
                  if (_foto != null)
                    Center(child: Image.file(_foto!, height: 120)),

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
                              child: LogoSpinner(size: 20, strokeWidth: 2),
                            )
                            : const Text('Crear cuenta'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white70,
                    ),
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
