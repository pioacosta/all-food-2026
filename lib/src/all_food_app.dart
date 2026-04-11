import 'package:all_food/src/features/staff/presentation/pages/alta_empleado_page.dart';
import 'package:all_food/src/features/staff/presentation/pages/clientes_pendientes_page.dart';
import 'package:all_food/src/shared/widgets/logo_loader.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:all_food/src/features/productos/presentation/pages/crear_producto_page.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/splash/splash_page.dart';

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
        scaffoldBackgroundColor: const Color(0xFF5B1718),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF7A2021),
          foregroundColor: Colors.white,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          labelStyle: TextStyle(color: Colors.white70),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white54),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white),
          ),
          errorStyle: TextStyle(color: Color(0xFFdfaaa4)),
          errorBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFFF8A80)),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFFF8A80)),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFFFFFFF),
            foregroundColor: Colors.black,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white70),
          ),
        ),
      ),
      initialRoute: '/session',
      routes: {
        '/session': (_) => SessionGate(supabaseReady: supabaseReady),

        '/home': (_) => HomePage(supabaseReady: supabaseReady),

        '/crear-producto': (_) => CrearProductoPage(supabaseReady: supabaseReady),

        '/alta-empleado': (_) => AltaEmpleadoPage(supabaseReady: supabaseReady),

        '/aprobacion-clientes': (_) => ClientesPendientesPage(supabaseReady: supabaseReady),

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
            if (!perfilSnapshot.hasData) {
              return const LogoLoader();
            }

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
