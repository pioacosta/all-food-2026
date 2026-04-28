import 'package:all_food/src/features/carta/presentation/pages/carta_cliente.dart';
import 'package:all_food/src/features/carta/presentation/pages/carta_page.dart';
import 'package:all_food/src/features/clientes/presentation/pages/alta_clientes_page.dart';
import 'package:all_food/src/features/consultas/presentation/pages/consultas_page.dart';
import 'package:all_food/src/features/mesas/presentation/pages/asignar_mesa.dart';
import 'package:all_food/src/features/pedidos/presentation/pages/cliente_pedido_page.dart';
import 'package:all_food/src/features/pedidos/presentation/pages/pedidos_mozo_page.dart';
import 'package:all_food/src/features/pedidos/presentation/pages/pedidos_sector_page.dart';
import 'package:all_food/src/features/staff/presentation/pages/alta_empleado_page.dart';
import 'package:all_food/src/features/clientes/presentation/pages/clientes_pendientes_page.dart';
import 'package:all_food/src/features/mesas/presentation/pages/crear_mesa_page.dart';
import 'package:all_food/src/features/mesas/presentation/pages/ver_editar_mesas_page.dart';
import 'package:all_food/src/shared/widgets/logo_loader.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:all_food/src/features/productos/presentation/pages/crear_producto_page.dart';
import 'package:all_food/src/shared/theme/app_ui.dart';
import 'package:all_food/src/features/auth/presentation/pages/login_entry_page.dart';
import 'package:all_food/src/features/home/presentation/pages/home_page.dart';
import 'package:all_food/src/features/splash/splash_page.dart';

class AllFoodApp extends StatelessWidget {
  const AllFoodApp({
    required this.supabaseReady,
    this.initializationMessage,
    super.key,
  });

  final bool supabaseReady;
  final String? initializationMessage;

  @override
  Widget build(BuildContext context) {
    // Esquema de color base para mantener coherencia visual.
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFB71C1C),
      brightness: Brightness.light,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'All Food',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: AppUi.fondoMedio,
        textTheme: GoogleFonts.nunitoTextTheme().apply(
          bodyColor: AppUi.texto,
          displayColor: AppUi.texto,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppUi.fondoSuperior,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Color(0x22FFFFFF),
          labelStyle: TextStyle(color: AppUi.textoSecundario),
          floatingLabelStyle: TextStyle(color: AppUi.acento),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white60),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppUi.acento, width: 1.6),
          ),
          errorStyle: TextStyle(color: Color(0xFFFFD2CC)),
          errorBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFFF8A80)),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFFF8A80)),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppUi.acento,
            foregroundColor: const Color(0xFF4A0E10),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white70, width: 1.4),
          ),
        ),
      ),
      initialRoute: '/session',
      routes: {
        '/session': (_) => SessionGate(supabaseReady: supabaseReady),

        '/home': (_) => HomePage(supabaseReady: supabaseReady),

        '/crear-producto':
            (_) => CrearProductoPage(supabaseReady: supabaseReady),

        '/carta': (context) {
          final rawArgs = ModalRoute.of(context)!.settings.arguments;
          final tipo = rawArgs is String ? rawArgs : null;
          return CartaPage(initialCategoria: tipo);
        },

        '/carta-cliente': (context) {
          final rawArgs = ModalRoute.of(context)!.settings.arguments;
          if (rawArgs is String) {
            return CartaClientePage(initialCategoria: rawArgs);
          }

          final args = (rawArgs as Map<String, dynamic>?) ?? const {};
          return CartaClientePage(
            initialCategoria: args['tipo'] as String?,
            mesaId: args['mesaId'] as String?,
            numeroMesa: (args['numeroMesa'] as num?)?.toInt(),
          );
        },

        '/pedido-cliente': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
          return ClientePedidoPage(
            mesaId: args['mesaId'] as String,
            numeroMesa: (args['numeroMesa'] as num).toInt(),
          );
        },

        '/pedidos-mozo': (_) => const PedidosMozoPage(),
        '/pedidos-cocina': (_) => const PedidosSectorPage(sector: 'cocina'),
        '/pedidos-bar': (_) => const PedidosSectorPage(sector: 'bar'),

        '/alta-empleado': (_) => AltaEmpleadoPage(supabaseReady: supabaseReady),

        '/crear-mesa': (_) => CrearMesaPage(supabaseReady: supabaseReady),

        '/ver-editar-mesas':
            (_) => VerEditarMesasPage(supabaseReady: supabaseReady),

        '/asignar-mesa': (_) => AsignarMesaPage(supabaseReady: supabaseReady),

        '/aprobacion-clientes':
            (_) => ClientesPendientesPage(supabaseReady: supabaseReady),

        '/alta-clientes': (_) => AltaClientePage(supabaseReady: supabaseReady),

        '/consultas': (_) => ConsultasPage(supabaseReady: supabaseReady),

        '/login':
            (_) => LoginPage(
              supabaseReady: supabaseReady,
              initializationMessage: initializationMessage,
            ),
      },
    );
  }
}

class SessionGate extends StatefulWidget {
  const SessionGate({
    required this.supabaseReady,
    this.initializationMessage,
    super.key,
  });

  final bool supabaseReady;
  final String? initializationMessage;

  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  bool _splashDone = false;
  int _perfilRetryCount = 0;
  bool _retryProgramado = false;

  static const int _maxPerfilRetries = 8;
  static const Duration _perfilRetryDelay = Duration(milliseconds: 450);

  void _programarRetryPerfil() {
    if (_retryProgramado) return;
    _retryProgramado = true;

    Future.delayed(_perfilRetryDelay, () {
      if (!mounted) return;
      setState(() {
        _retryProgramado = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.supabaseReady) {
      return LoginPage(
        supabaseReady: widget.supabaseReady,
        initializationMessage: widget.initializationMessage,
      );
    }

    // Splash todavía no terminó, lo mostramos dentro del SessionGate
    if (!_splashDone) {
      return SplashPage(
        supabaseReady: widget.supabaseReady,
        onFinished: () => setState(() => _splashDone = true), // 👈
      );
    }

    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      initialData: AuthState(
        AuthChangeEvent.initialSession,
        Supabase.instance.client.auth.currentSession,
      ),
      builder: (context, snapshot) {
        final session = snapshot.data?.session;

        if (session == null) {
          _perfilRetryCount = 0;
          _retryProgramado = false;
          return LoginPage(
            supabaseReady: widget.supabaseReady,
            initializationMessage: widget.initializationMessage,
          );
        }

        return FutureBuilder(
          future:
              Supabase.instance.client
                  .from('perfiles')
                  .select()
                  .eq('id', session.user.id)
                  .single(),
          builder: (context, perfilSnapshot) {
            if (perfilSnapshot.connectionState == ConnectionState.waiting) {
              return const LogoLoader();
            }

            if (perfilSnapshot.hasError || !perfilSnapshot.hasData) {
              if (_perfilRetryCount < _maxPerfilRetries) {
                _perfilRetryCount++;
                _programarRetryPerfil();
                return const LogoLoader();
              }

              Future.microtask(() async {
                await Supabase.instance.client.auth.signOut();
              });

              return LoginPage(
                supabaseReady: widget.supabaseReady,
                errorMessage:
                    'No se pudo cargar tu perfil. Intenta ingresar nuevamente.',
              );
            }

            _perfilRetryCount = 0;
            _retryProgramado = false;

            final estado = perfilSnapshot.data!['estado_registro'];

            if (estado == 'aprobado') {
              return HomePage(supabaseReady: widget.supabaseReady);
            }

            final mensaje =
                estado == 'pendiente_aprobacion'
                    ? 'Tu cuenta está pendiente de aprobación.'
                    : 'Tu cuenta ha sido rechazada.';

            Future.microtask(() async {
              await Supabase.instance.client.auth.signOut();
            });

            return LoginPage(
              supabaseReady: widget.supabaseReady,
              errorMessage: mensaje,
            );
          },
        );
      },
    );
  }
}
