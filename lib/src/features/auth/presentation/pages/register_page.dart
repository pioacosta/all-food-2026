import 'dart:io';
import 'package:all_food/src/features/auth/widgets/auth_background.dart';
import 'package:all_food/src/features/auth/widgets/auth_card.dart';
import 'package:all_food/src/shared/dni_qr/dni_qr_data.dart';
import 'package:all_food/src/shared/dni_qr/dni_qr_scanner_page.dart';
import 'package:all_food/src/shared/errors/app_error_mapper.dart';
import 'package:all_food/src/shared/theme/app_ui.dart';
import 'package:all_food/src/shared/widgets/logo_spinner.dart';
import 'package:all_food/src/features/auth/data/repositories/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  // Repositorio que concentra el flujo de alta contra Supabase.
  final _authRepository = AuthRepository();

  var _isLoading = false;
  bool _mostrarPassword = false;
  bool _mostrarConfirmPassword = false;

  Widget _campoObligatorioConAsterisco({required Widget child}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: child),
        const SizedBox(width: 8),
        const Padding(
          padding: EdgeInsets.only(top: 14),
          child: Text(
            '*',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

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

  // Toma foto desde camara y actualiza la vista previa si fue exitosa.
  Future<void> _tomarFoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.camera);
    if (picked == null) return;

    setState(() {
      _foto = File(picked.path);
    });
  }

  Future<void> _registrar() async {
    // Valida obligatorios de forma compacta en el propio campo (lado derecho).
    final faltanObligatorios =
        _nombreController.text.trim().isEmpty ||
        _apellidoController.text.trim().isEmpty ||
        _dniController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty;

    if (faltanObligatorios) {
      _mostrarMensaje('Completa los campos obligatorios.', esError: true);
      return;
    }

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
      // La pantalla solo recolecta datos; el repositorio ejecuta el alta completa.
      await _authRepository.registerClient(
        nombres: _nombreController.text.trim(),
        apellidos: _apellidoController.text.trim(),
        dni: _dniController.text.trim(),
        correo: _emailController.text.trim(),
        password: _passwordController.text,
        foto: _foto!,
      );

      try {
        await Supabase.instance.client.functions.invoke(
          'notificar-cliente-pendiente',
          body: {
            'clienteNombre':
                '${_nombreController.text.trim()} ${_apellidoController.text.trim()}',
          },
        );
      } catch (_) {
        // mandar error
      }

      if (!mounted) return;

      _mostrarMensaje(
        'Registro exitoso. Esperando aprobación.',
        esError: false,
      );

      Navigator.of(context).pop();
    } catch (error) {
      _mostrarMensaje(
        AppErrorMapper.toUserMessage(
          error,
          fallbackMessage: 'Ocurrió un error inesperado al registrar.',
        ),
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

  // Abre scanner QR/PDF417 para autocompletar datos del DNI.
  Future<void> _abrirLectorQrDni() async {
    final resultado = await Navigator.of(context).push<DniQrData>(
      MaterialPageRoute(builder: (_) => const DniQrScannerPage()),
    );

    if (!mounted || resultado == null) return;

    _apellidoController.text = resultado.apellido ?? '';
    _nombreController.text = resultado.nombre ?? '';
    _dniController.text = resultado.dni ?? '';

    _mostrarMensaje('QR aplicado correctamente', esError: false);
  }

  void _mostrarMensaje(String mensaje, {required bool esError}) {
    // Punto unico para mensajes al usuario.
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor:
              esError ? AppUi.error : AppUi.exito,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return AuthBackground(
      child: Center(
        child: AuthCard(
          children: [
            Theme(
              data: Theme.of(context).copyWith(
                inputDecorationTheme: const InputDecorationTheme(
                  // Campos mas compactos y errores en blanco sobre fondo rojo.
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  labelStyle: TextStyle(color: Colors.white70),
                  floatingLabelStyle: TextStyle(color: Colors.white),
                  constraints: BoxConstraints(minHeight: 44),
                  errorMaxLines: 1,
                  errorStyle: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    height: 1.1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  errorBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white70),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
              ),
              child: Form(
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
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: _campoObligatorioConAsterisco(
                        child: TextFormField(
                          controller: _nombreController,
                          style: const TextStyle(color: Colors.white),
                          textCapitalization: TextCapitalization.words,
                          validator: (value) {
                            return null;
                          },
                          decoration: const InputDecoration(
                            labelText: 'Nombre/s',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: _campoObligatorioConAsterisco(
                        child: TextFormField(
                          controller: _apellidoController,
                          style: const TextStyle(color: Colors.white),
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Apellido/s',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            return null;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: _campoObligatorioConAsterisco(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _dniController,
                                style: const TextStyle(color: Colors.white),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: const InputDecoration(
                                  labelText: 'DNI',
                                  border: OutlineInputBorder(),
                                  counterText: '',
                                ),
                                maxLength: 8,
                                validator: (value) {
                                  final text = value?.trim() ?? '';
                                  if (!RegExp(r'^\d+$').hasMatch(text)) {
                                    return 'El DNI debe ser numérico.';
                                  }
                                  if (text.length < 7) {
                                    return 'DNI inválido.';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 45,
                              child: FilledButton(
                                onPressed: _abrirLectorQrDni,
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                ),
                                child: const Icon(Icons.qr_code_scanner),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: _campoObligatorioConAsterisco(
                        child: TextFormField(
                          controller: _emailController,
                          style: const TextStyle(color: Colors.white),
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Correo electrónico',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            final email = value?.trim() ?? '';
                            final pattern = RegExp(
                              r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                            );
                            if (!pattern.hasMatch(email)) {
                              return 'Correo electrónico inválido.';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_foto == null)
                      ElevatedButton(
                        onPressed: _tomarFoto,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppUi.acento,
                          foregroundColor: const Color(0xFF4A0E10),
                          minimumSize: const Size.fromHeight(50),
                          textStyle: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                        child: const Text('Tomar foto'),
                      ),
                    const SizedBox(height: 10),

                    if (_foto != null)
                      Center(
                        // La vista previa permite reemplazar la foto sin mostrar otro boton.
                        child: InkWell(
                          onTap: _tomarFoto,
                          borderRadius: BorderRadius.circular(10),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(_foto!, height: 120),
                          ),
                        ),
                      ),

                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: _campoObligatorioConAsterisco(
                        child: TextFormField(
                          controller: _passwordController,
                          style: const TextStyle(color: Colors.white),
                          obscureText: !_mostrarPassword,
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _mostrarPassword = !_mostrarPassword;
                                });
                              },
                              icon: Icon(
                                _mostrarPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          validator: (value) {
                            final password = value ?? '';
                            if (password.length < 6) {
                              return 'La contraseña debe tener al menos 6 caracteres.';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: _campoObligatorioConAsterisco(
                        child: TextFormField(
                          controller: _confirmPasswordController,
                          style: const TextStyle(color: Colors.white),
                          obscureText: !_mostrarConfirmPassword,
                          decoration: InputDecoration(
                            labelText: 'Confirmar contraseña',
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _mostrarConfirmPassword =
                                      !_mostrarConfirmPassword;
                                });
                              },
                              icon: Icon(
                                _mostrarConfirmPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value != _passwordController.text) {
                              return 'Las contraseñas no coinciden.';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _isLoading ? null : _registrar,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppUi.acento,
                        foregroundColor: const Color(0xFF4A0E10),
                        minimumSize: const Size.fromHeight(50),
                        textStyle: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
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
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed:
                          _isLoading
                              ? null
                              : () {
                                // Vuelve al login manteniendo la navegacion simple.
                                Navigator.of(context).pop();
                              },
                      child: const Text(
                        '¿Ya tenés cuenta? Ingresá acá',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
