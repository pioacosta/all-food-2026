import 'package:flutter/material.dart';

class LogoLoader extends StatefulWidget {
  const LogoLoader({super.key});

  @override
  State<LogoLoader> createState() => _LogoLoaderState();
}

class _LogoLoaderState extends State<LogoLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  // late final Animation<double> _pulse;
  late final Animation<double> _bounce;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();

    _bounce = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        // Interval 0.0 a 0.6 anima, 0.6 a 1.0 pausa en el valor final
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF9e2325),
      body: Center(
        child: ScaleTransition(
          scale: _bounce,
          child: Image.asset('assets/images/logo.png', width: 200, height: 200),
        ),
      ),
    );
  }
}
