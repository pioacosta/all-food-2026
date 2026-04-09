import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({
    required this.supabaseReady,
    required this.onFinished, // 👈
    super.key,
  });

  final bool supabaseReady;
  final VoidCallback onFinished;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _logoSlide;
  late final Animation<Offset> _namesSlide;
  late final Animation<double> _exitFade;

  // Animación por letra: fade + scale escalonado
  static const _letters = ['A', 'L', 'L', ' ', 'F', 'O', 'O', 'D'];
  late final List<Animation<double>> _letterFades;
  late final List<Animation<double>> _letterScales;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    const letterDuration = 0.09;
    const letterDelay = 0.04;

    _letterFades = List.generate(_letters.length, (i) {
      final start = i * letterDelay;
      final end = (start + letterDuration).clamp(0.0, 0.45);
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    });

    _letterScales = List.generate(_letters.length, (i) {
      final start = i * letterDelay;
      final end = (start + letterDuration).clamp(0.0, 0.45);
      return Tween<double>(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end, curve: Curves.easeOutBack),
        ),
      );
    });

    _logoSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 0.42, curve: Curves.bounceOut),
      ),
    );

    _namesSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.4, curve: Curves.easeOut),
      ),
    );

    _exitFade = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.82, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.forward();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        widget.onFinished(); // 👈 en vez de Navigator.pushReplacement
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final letterStyle = TextStyle(
      fontFamily: 'ArchivoBlack',
      fontSize: 72,
      color: Colors.white,
      letterSpacing: -6,
      height: 1,
    );

    return Scaffold(
      // backgroundColor: const Color(0xFFFF0051),
      // 1ra opción, está copado pero es full fluor
      backgroundColor: const Color(0xFF9e2325),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final opacity = _fadeAnim.value * _exitFade.value;
            return Opacity(opacity: opacity.clamp(0.0, 1.0), child: child);
          },
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // titulo letra por letra
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: List.generate(_letters.length, (i) {
                        if (_letters[i] == ' ') {
                          return const SizedBox(width: 16);
                        }
                        return Opacity(
                          opacity: _letterFades[i].value,
                          child: Transform.scale(
                            scale: _letterScales[i].value,
                            child: Text(_letters[i], style: letterStyle),
                          ),
                        );
                      }),
                    );
                  },
                ),

                const SizedBox(height: 32),

                // logo
                SlideTransition(
                  position: _logoSlide,
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 110,
                    height: 110,
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 32),

                // nombres
                SlideTransition(
                  position: _namesSlide,
                  child: Column(
                    children:
                        ['Lezcano Adrián', 'Acosta Pio', 'Bordón Luciano']
                            .map(
                              (name) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 2,
                                ),
                                child: Text(
                                  name,
                                  style: GoogleFonts.nunito(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
