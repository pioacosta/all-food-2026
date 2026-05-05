import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

import 'package:all_food/src/features/pedidos/data/repositories/pedidos_repository.dart';
import 'package:all_food/src/shared/errors/app_error_mapper.dart';
import 'package:all_food/src/shared/theme/app_ui.dart';
import 'package:all_food/src/shared/widgets/logo_spinner.dart';
import 'package:all_food/src/shared/utils/error_feedback.dart';
import 'package:shared_preferences/shared_preferences.dart';

class JuegosDescuentoPage extends StatefulWidget {
  const JuegosDescuentoPage({
    required this.pedidoId,
    required this.descuentoActual,
    super.key,
  });

  final String pedidoId;
  final double descuentoActual;

  @override
  State<JuegosDescuentoPage> createState() => _JuegosDescuentoPageState();
}

class _JuegosDescuentoPageState extends State<JuegosDescuentoPage> {
  final _repo = PedidosRepository();
  final _random = Random();

  bool _cargando = true;
  bool _procesando = false;
  bool _clienteRegistrado = false;
  double _descuentoAplicado = 0;
  final Map<int, bool> _intentoConsumido = {10: false, 15: false, 20: false};

  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  Future<void> _inicializar() async {
    try {
      final registrado = await _repo.esClienteRegistradoActual();
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _clienteRegistrado = registrado;
        _descuentoAplicado = widget.descuentoActual;
        _intentoConsumido[10] =
            prefs.getBool(_keyIntento(porcentaje: 10)) ?? false;
        _intentoConsumido[15] =
            prefs.getBool(_keyIntento(porcentaje: 15)) ?? false;
        _intentoConsumido[20] =
            prefs.getBool(_keyIntento(porcentaje: 20)) ?? false;
      });
    } catch (error) {
      if (!mounted) return;
      _mostrarMensaje(
        AppErrorMapper.toUserMessage(
          error,
          fallbackMessage: 'No se pudo cargar la sección de juegos.',
        ),
        esError: true,
      );
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  String _keyIntento({required int porcentaje}) =>
      'juego_${widget.pedidoId}_$porcentaje';

  Future<void> _guardarIntento(int porcentaje) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIntento(porcentaje: porcentaje), true);
  }

  Future<void> _jugarNumero10() async {
    if (_procesando) return;
    if (!_clienteRegistrado) {
      _mostrarMensaje(
        'Solo clientes registrados pueden obtener descuentos con juegos.',
        esError: true,
      );
      return;
    }
    final primerIntentoDisponible = _intentoConsumido[10] != true;
    final eleccion = await Navigator.of(
      context,
    ).push<int>(MaterialPageRoute(builder: (_) => const _JuegoNumeroPage()));
    if (eleccion == null) return;

    final acierto = _random.nextInt(6) + 1 == eleccion;
    if (primerIntentoDisponible) {
      await _guardarIntento(10);
      if (!mounted) return;
      setState(() => _intentoConsumido[10] = true);
    }
    if (!acierto) {
      _mostrarMensaje(
        primerIntentoDisponible
            ? 'No acertaste. Solo cuenta el primer intento.'
            : 'No acertaste. Rejugar no otorga descuento.',
        esError: true,
      );
      return;
    }
    if (!primerIntentoDisponible) {
      _mostrarMensaje(
        'Ganaste, pero ya consumiste el primer intento: no se aplica descuento.',
        esError: false,
      );
      return;
    }
    await _aplicarDescuentoSiCorresponde(10);
  }

  Future<void> _jugarComidas15() async {
    if (_procesando) return;
    if (!_clienteRegistrado) {
      _mostrarMensaje(
        'Solo clientes registrados pueden obtener descuentos con juegos.',
        esError: true,
      );
      return;
    }
    final primerIntentoDisponible = _intentoConsumido[15] != true;
    final gano = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const _JuegoComidasPage()));
    if (gano == null) return;

    if (primerIntentoDisponible) {
      await _guardarIntento(15);
      if (!mounted) return;
      setState(() => _intentoConsumido[15] = true);
    }
    if (!gano) {
      _mostrarMensaje(
        primerIntentoDisponible
            ? 'No alcanzaste la meta del juego de comidas.'
            : 'No alcanzaste la meta. Rejugar no otorga descuento.',
        esError: true,
      );
      return;
    }
    if (!primerIntentoDisponible) {
      _mostrarMensaje(
        'Ganaste, pero ya consumiste el primer intento: no se aplica descuento.',
        esError: false,
      );
      return;
    }
    await _aplicarDescuentoSiCorresponde(15);
  }

  Future<void> _jugarSnake20() async {
    if (_procesando) return;
    if (!_clienteRegistrado) {
      _mostrarMensaje(
        'Solo clientes registrados pueden obtener descuentos con juegos.',
        esError: true,
      );
      return;
    }
    final primerIntentoDisponible = _intentoConsumido[20] != true;
    final gano = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const _JuegoSnakePage()));
    if (gano == null) return;

    if (primerIntentoDisponible) {
      await _guardarIntento(20);
      if (!mounted) return;
      setState(() => _intentoConsumido[20] = true);
    }
    if (!gano) {
      _mostrarMensaje(
        primerIntentoDisponible
            ? 'Perdiste en Snake. Necesitabas comer al menos 15 veces sin perder.'
            : 'Perdiste en Snake. Rejugar no otorga descuento.',
        esError: true,
      );
      return;
    }
    if (!primerIntentoDisponible) {
      _mostrarMensaje(
        'Ganaste, pero ya consumiste el primer intento: no se aplica descuento.',
        esError: false,
      );
      return;
    }
    await _aplicarDescuentoSiCorresponde(20);
  }

  Future<void> _aplicarDescuentoSiCorresponde(int porcentaje) async {
    setState(() => _procesando = true);
    try {
      if (_descuentoAplicado > 0) {
        _mostrarMensaje(
          'Ganaste, pero ya tenías un descuento del ${_descuentoAplicado.toStringAsFixed(0)}%.',
          esError: false,
        );
        return;
      }
      final aplicado = await _repo.aplicarDescuentoJuego(
        pedidoId: widget.pedidoId,
        porcentaje: porcentaje,
      );
      if (!mounted) return;
      if (aplicado) {
        setState(() => _descuentoAplicado = porcentaje.toDouble());
        _mostrarMensaje(
          '¡Ganaste! Se aplicó $porcentaje% a la cuenta final.',
          esError: false,
        );
      } else {
        _mostrarMensaje(
          'Ya existe un descuento aplicado en este pedido.',
          esError: false,
        );
      }
    } catch (error) {
      if (!mounted) return;
      _mostrarMensaje(
        AppErrorMapper.toUserMessage(
          error,
          fallbackMessage: 'No se pudo aplicar el descuento.',
        ),
        esError: true,
      );
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  void _mostrarMensaje(String mensaje, {required bool esError}) {
    if (esError) ErrorFeedback.vibrate();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: esError ? AppUi.error : AppUi.exito,
      ),
    );
  }

  VoidCallback? _onPlayPorJuego(int index) {
    if (_procesando) return null;
    return () => _mostrarModalReglas(index);
  }

  Future<void> _mostrarModalReglas(int index) async {
    final config = _juegos[index];
    final confirmo = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ModalReglasJuego(config: config),
    );
    if (confirmo != true) return;
    switch (index) {
      case 0:
        await _jugarNumero10();
      case 1:
        await _jugarComidas15();
      case 2:
        await _jugarSnake20();
    }
  }

  bool _intentoDeJuego(int index) {
    return switch (index) {
      0 => _intentoConsumido[10] == true,
      1 => _intentoConsumido[15] == true,
      2 => _intentoConsumido[20] == true,
      _ => false,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Juegos y descuentos')),
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppUi.fondoPrincipal),
        child: SafeArea(
          child:
              _cargando
                  ? const Center(child: LogoSpinner(size: 48, strokeWidth: 3))
                  : Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Hero ────────────────────────────────────────
                        _HeroJuegosCard(
                          descuentoAplicado: _descuentoAplicado,
                          clienteRegistrado: _clienteRegistrado,
                          intentosConsumidos: _intentoConsumido,
                        ),

                        const SizedBox(height: 12),

                        // ── Cards de juegos — ocupan el resto ───────────
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (var i = 0; i < _juegos.length; i++) ...[
                                _JuegoCard(
                                  config: _juegos[i],
                                  intentoUsado: _intentoDeJuego(i),
                                  onPlay: _onPlayPorJuego(i),
                                ),
                                if (i < _juegos.length - 1)
                                  const SizedBox(height: 10),
                              ],
                            ],
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

class _JuegoConfig {
  const _JuegoConfig({
    required this.numero,
    required this.titulo,
    required this.tagline, // ← nuevo
    required this.porcentaje,
    required this.bgColor,
    required this.accentColor,
    required this.textColor,
    required this.subtextColor,
    required this.icon,
    required this.reglas, // ← nuevo
  });

  final int numero;
  final String titulo;
  final String tagline; // ← nuevo
  final int porcentaje;
  final Color bgColor;
  final Color accentColor;
  final Color textColor;
  final Color subtextColor;
  final IconData icon;
  final String reglas; // ← nuevo
}

const _juegos = [
  _JuegoConfig(
    numero: 1,
    titulo: 'Adivinar número',
    tagline: 'Elegí un número del 1 al 6.',
    porcentaje: 10,
    bgColor: Color(0xFFBBAA88),
    accentColor: Color(0xFF5C1F1F),
    textColor: Color(0xFF3A1010),
    subtextColor: Color(0xFF7A4040),
    icon: Icons.casino_rounded,
    reglas:
        'Elegí un número del 1 al 6. Si el número que elegís coincide con el resultado aleatorio, ganás un 10% de descuento en tu pedido.',
  ),
  _JuegoConfig(
    numero: 2,
    titulo: 'Comidas y bombas',
    tagline: 'Sumá puntos, evitá bombas.',
    porcentaje: 15,
    bgColor: Color(0xFFBBAA88),
    accentColor: Color(0xFF8D6200),
    textColor: Color(0xFF4A3200),
    subtextColor: Color(0xFF7A5800),
    icon: Icons.fastfood_rounded,
    reglas:
        'Tocá comidas para sumar puntos y evitá las bombas. Si llegás a 120 puntos sin explotar, ganás un 15% de descuento.',
  ),
  _JuegoConfig(
    numero: 3,
    titulo: 'Snake clásico',
    tagline: 'Comé 15 veces sin perder.',
    porcentaje: 20,
    bgColor: Color(0xFFBBAA88),
    accentColor: Color(0xFF2A3A4A),
    textColor: Color(0xFF2A3A4A),
    subtextColor: Color(0xFF2A3A4A),
    icon: Icons.videogame_asset_rounded,
    reglas:
        'Deslizá el dedo en cualquier parte de la pantalla para mover la serpiente. Comé al menos 15 veces sin chocar con las paredes ni con vos mismo para ganar el 20% de descuento.',
  ),
];

class _HeroJuegosCard extends StatelessWidget {
  const _HeroJuegosCard({
    required this.descuentoAplicado,
    required this.clienteRegistrado,
    required this.intentosConsumidos,
  });

  final double descuentoAplicado;
  final bool clienteRegistrado;
  final Map<int, bool> intentosConsumidos;

  @override
  Widget build(BuildContext context) {
    final tieneDescuento = descuentoAplicado > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: const Color(0xFF5C1F1F),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Body según estado ─────────────────────────────
          if (tieneDescuento) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Descuento\nganado',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
                Text(
                  '${descuentoAplicado.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontFamily: 'ArchivoBlack',
                    color: AppUi.acento,
                    fontSize: 52,
                    height: 1,
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ganá jugando\ny obtené un descuento',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
                Text(
                  '?%',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.15),
                    fontSize: 52,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 14),
          Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
          const SizedBox(height: 12),

          // ── Reglas ────────────────────────────────────────
          if (!clienteRegistrado) ...[
            Text(
              'Solo clientes registrados pueden ganar descuentos jugando.',
              style: TextStyle(
                color: const Color(0xFFE8A87C).withValues(alpha: 0.8),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ] else ...[
            Text(
              '· Solo cuenta el primer intento.\n· Los descuentos no se acumulan.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35),
                fontSize: 16, // ← subí de 12 a 14
                height: 1.6,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card de juego
// ─────────────────────────────────────────────────────────────────────────────
class _JuegoCard extends StatelessWidget {
  const _JuegoCard({
    required this.config,
    required this.intentoUsado,
    required this.onPlay,
  });

  final _JuegoConfig config;
  final bool intentoUsado;
  final VoidCallback? onPlay;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPlay,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            height: double.infinity,
            decoration: BoxDecoration(
              color: config.bgColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // Top: badge + porcentaje
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            // decoration: BoxDecoration(
                            //   color: config.accentColor.withValues(alpha: 0.12),
                            //   borderRadius: BorderRadius.circular(20),
                            // ),
                            child: Text(
                              'Juego ${config.numero}',
                              style: TextStyle(
                                color: config.accentColor,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                          Text(
                            '${config.porcentaje}%',
                            style: TextStyle(
                              color: config.accentColor,
                              fontFamily: 'ArchivoBlack',
                              fontSize: 35,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                      // Título + descripción
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                config.icon,
                                color: config.accentColor,
                                size: 20,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                config.titulo,
                                style: TextStyle(
                                  color: config.textColor,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            config.tagline,
                            style: TextStyle(
                              color: config.subtextColor,
                              fontSize: 15,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Botón
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: config.accentColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              intentoUsado
                                  ? Icons.refresh_rounded
                                  : Icons.play_arrow_rounded,
                              color: config.bgColor,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              intentoUsado
                                  ? 'Rejugar (sin descuento)'
                                  : 'Jugar ahora',
                              style: TextStyle(
                                color: config.bgColor,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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

class _ModalReglasJuego extends StatelessWidget {
  const _ModalReglasJuego({required this.config});

  final _JuegoConfig config;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      decoration: BoxDecoration(
        color: config.bgColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(config.icon, color: config.accentColor, size: 22),
              const SizedBox(width: 8),
              Text(
                config.titulo,
                style: TextStyle(
                  color: config.textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '${config.porcentaje}%',
                style: TextStyle(
                  color: config.accentColor,
                  fontFamily: 'ArchivoBlack',
                  fontSize: 28,
                  height: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            config.reglas,
            style: TextStyle(
              color: config.subtextColor,
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: config.accentColor,
                    side: BorderSide(color: config.accentColor),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: config.accentColor,
                    foregroundColor: config.bgColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Jugar',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EntidadJuego {
  _EntidadJuego({
    required this.id,
    required this.x,
    required this.y,
    required this.tipo,
    required this.puntos,
    required this.icono,
  });

  final int id;
  final double x;
  final double y;
  final String tipo;
  final int puntos;
  final IconData icono;
}

class _JuegoNumeroPage extends StatelessWidget {
  const _JuegoNumeroPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Juego de n\u00FAmero')),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: AppUi.fondoPrincipal),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: AppUi.panelDecoracion(radius: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Adivin\u00E1 el n\u00FAmero del 1 al 6',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Seleccion\u00E1 un n\u00FAmero. Si coincide con el n\u00FAmero sorteado, gan\u00E1s.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppUi.textoSecundario),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: GridView.builder(
                      itemCount: 6,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: 1.35,
                          ),
                      itemBuilder: (context, index) {
                        final numero = index + 1;
                        return FilledButton(
                          onPressed: () => Navigator.of(context).pop(numero),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppUi.acento,
                            foregroundColor: const Color(0xFF4A0E10),
                            textStyle: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          child: Text('$numero'),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _JuegoComidasPage extends StatefulWidget {
  const _JuegoComidasPage();

  @override
  State<_JuegoComidasPage> createState() => _JuegoComidasPageState();
}

class _JuegoComidasPageState extends State<_JuegoComidasPage> {
  final _random = Random();
  final List<_EntidadJuego> _entidades = [];

  Timer? _timerJuego;
  Timer? _timerSpawn;
  int _segundos = 25;
  int _puntaje = 0;
  int _idSeq = 0;
  double _ancho = 0;
  double _alto = 0;

  static const int _meta = 120;

  @override
  void initState() {
    super.initState();
    _timerJuego = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_segundos <= 1) {
        _finalizar();
      } else {
        setState(() => _segundos -= 1);
      }
    });
    _timerSpawn = Timer.periodic(const Duration(milliseconds: 700), (_) {
      _spawnEntidad();
    });
  }

  @override
  void dispose() {
    _timerJuego?.cancel();
    _timerSpawn?.cancel();
    super.dispose();
  }

  void _spawnEntidad() {
    if (!mounted || _ancho <= 0 || _alto <= 0) return;

    final esBomba = _random.nextDouble() < 0.28;
    late final _EntidadJuego entidad;

    if (esBomba) {
      entidad = _EntidadJuego(
        id: _idSeq++,
        x: _random.nextDouble() * (_ancho - 56),
        y: _random.nextDouble() * (_alto - 56),
        tipo: 'bomba',
        puntos: -25,
        icono: Icons.warning_amber_rounded,
      );
    } else {
      final tipo = _random.nextInt(3);
      if (tipo == 0) {
        entidad = _EntidadJuego(
          id: _idSeq++,
          x: _random.nextDouble() * (_ancho - 56),
          y: _random.nextDouble() * (_alto - 56),
          tipo: 'hamburguesa',
          puntos: 12,
          icono: Icons.lunch_dining,
        );
      } else if (tipo == 1) {
        entidad = _EntidadJuego(
          id: _idSeq++,
          x: _random.nextDouble() * (_ancho - 56),
          y: _random.nextDouble() * (_alto - 56),
          tipo: 'pizza',
          puntos: 18,
          icono: Icons.local_pizza,
        );
      } else {
        entidad = _EntidadJuego(
          id: _idSeq++,
          x: _random.nextDouble() * (_ancho - 56),
          y: _random.nextDouble() * (_alto - 56),
          tipo: 'helado',
          puntos: 25,
          icono: Icons.icecream,
        );
      }
    }

    setState(() => _entidades.add(entidad));

    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      setState(() {
        _entidades.removeWhere((e) => e.id == entidad.id);
      });
    });
  }

  void _tocarEntidad(_EntidadJuego entidad) {
    setState(() {
      _puntaje += entidad.puntos;
      _entidades.removeWhere((e) => e.id == entidad.id);
    });
  }

  void _finalizar() {
    _timerJuego?.cancel();
    _timerSpawn?.cancel();
    Navigator.of(context).pop(_puntaje >= _meta);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Juego comidas y bombas')),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: AppUi.fondoPrincipal),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: AppUi.panelDecoracion(radius: 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Puntaje: $_puntaje / $_meta',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        'Tiempo: $_segundos',
                        style: const TextStyle(color: AppUi.acento),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      _ancho = constraints.maxWidth;
                      _alto = constraints.maxHeight;
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Stack(
                          children:
                              _entidades
                                  .map(
                                    (e) => Positioned(
                                      left: e.x,
                                      top: e.y,
                                      child: GestureDetector(
                                        onTap: () => _tocarEntidad(e),
                                        child: Container(
                                          width: 52,
                                          height: 52,
                                          decoration: BoxDecoration(
                                            color:
                                                e.tipo == 'bomba'
                                                    ? const Color(0xFF992E2E)
                                                    : const Color(0xFF2D6A4F),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 1.2,
                                            ),
                                          ),
                                          child: Icon(
                                            e.icono,
                                            color: Colors.white,
                                            size: 28,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Comidas: +12, +18 y +25. Bomba: -25.',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _DireccionSnake { arriba, abajo, izquierda, derecha }

class _JuegoSnakePage extends StatefulWidget {
  const _JuegoSnakePage();

  @override
  State<_JuegoSnakePage> createState() => _JuegoSnakePageState();
}

class _JuegoSnakePageState extends State<_JuegoSnakePage> {
  static const int _gridX = 14;
  static const int _metaComidas = 15;

  final _random = Random();
  final List<Point<int>> _snake = [
    const Point(7, 10),
    const Point(6, 10),
    const Point(5, 10),
  ];
  _DireccionSnake _direccion = _DireccionSnake.derecha;
  _DireccionSnake _direccionPendiente = _DireccionSnake.derecha;
  Timer? _timer;
  Point<int> _comida = const Point(10, 7);
  bool _terminado = false;
  bool _gano = false;
  int _comidas = 0;
  int _gridY = 20;

  Offset? _panInicio;

  @override
  void initState() {
    super.initState();
    _generarComida();
    _timer = Timer.periodic(const Duration(milliseconds: 170), (_) => _tick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _generarComida() {
    while (true) {
      final nueva = Point(_random.nextInt(_gridX), _random.nextInt(_gridY));
      if (!_snake.contains(nueva)) {
        _comida = nueva;
        return;
      }
    }
  }

  void _cambiarDireccion(_DireccionSnake nueva) {
    if ((_direccion == _DireccionSnake.arriba &&
            nueva == _DireccionSnake.abajo) ||
        (_direccion == _DireccionSnake.abajo &&
            nueva == _DireccionSnake.arriba) ||
        (_direccion == _DireccionSnake.izquierda &&
            nueva == _DireccionSnake.derecha) ||
        (_direccion == _DireccionSnake.derecha &&
            nueva == _DireccionSnake.izquierda)) {
      return;
    }
    _direccionPendiente = nueva;
  }

  void _onPanStart(DragStartDetails details) {
    _panInicio = details.globalPosition;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_panInicio == null) return;

    final delta = details.globalPosition - _panInicio!;
    const umbral = 20.0;

    if (delta.distance < umbral) return;

    if (delta.dx.abs() > delta.dy.abs()) {
      _cambiarDireccion(
        delta.dx > 0 ? _DireccionSnake.derecha : _DireccionSnake.izquierda,
      );
    } else {
      _cambiarDireccion(
        delta.dy > 0 ? _DireccionSnake.abajo : _DireccionSnake.arriba,
      );
    }

    // Resetear el inicio para el siguiente swipe
    _panInicio = details.globalPosition;
  }

  void _tick() {
    if (!mounted || _terminado) return;

    _direccion = _direccionPendiente;

    final cabeza = _snake.first;
    Point<int> nuevaCabeza;

    switch (_direccion) {
      case _DireccionSnake.arriba:
        nuevaCabeza = Point(cabeza.x, cabeza.y - 1);
        break;
      case _DireccionSnake.abajo:
        nuevaCabeza = Point(cabeza.x, cabeza.y + 1);
        break;
      case _DireccionSnake.izquierda:
        nuevaCabeza = Point(cabeza.x - 1, cabeza.y);
        break;
      case _DireccionSnake.derecha:
        nuevaCabeza = Point(cabeza.x + 1, cabeza.y);
        break;
    }

    final chocaBorde =
        nuevaCabeza.x < 0 ||
        nuevaCabeza.y < 0 ||
        nuevaCabeza.x >= _gridX ||
        nuevaCabeza.y >= _gridY;
    final chocaCuerpo = _snake.contains(nuevaCabeza);

    if (chocaBorde || chocaCuerpo) {
      _finalizar(false);
      return;
    }

    setState(() {
      _snake.insert(0, nuevaCabeza);
      if (nuevaCabeza == _comida) {
        _comidas += 1;
        if (_comidas >= _metaComidas) {
          _finalizar(true);
          return;
        }
        _generarComida();
      } else {
        _snake.removeLast();
      }
    });
  }

  void _finalizar(bool gano) {
    _timer?.cancel();
    setState(() {
      _terminado = true;
      _gano = gano;
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      Navigator.of(context).pop(gano);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(gradient: AppUi.fondoPrincipal),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Header ──────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: AppUi.panelDecoracion(radius: 16),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Comidas',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.80),
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              '$_comidas / $_metaComidas',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontFamily: 'ArchivoBlack',
                                height: 1,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color:
                                _terminado
                                    ? (_gano ? AppUi.exito : AppUi.error)
                                    : Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _terminado
                                ? (_gano ? '¡Ganaste!' : 'Perdiste')
                                : 'En juego',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  // ── Tablero ─────────────────────────────────────
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final cellSize = constraints.maxWidth / _gridX;
                            final gridY =
                                (constraints.maxHeight / cellSize).floor();

                            // Actualizarlo si cambió
                            if (gridY != _gridY) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) setState(() => _gridY = gridY);
                              });
                            }

                            return CustomPaint(
                              size: Size(
                                constraints.maxWidth,
                                constraints.maxHeight,
                              ),
                              painter: _SnakePainter(
                                snake: _snake,
                                comida: _comida,
                                gridX: _gridX,
                                gridY:
                                    gridY, // ← el calculado dinámicamente, no _gridY
                                cellSize: cellSize,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Deslizá el dedo en cualquier dirección para mover la serpiente.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SnakePainter extends CustomPainter {
  const _SnakePainter({
    required this.snake,
    required this.comida,
    required this.gridX,
    required this.gridY,
    required this.cellSize,
  });

  final List<Point<int>> snake;
  final Point<int> comida;
  final int gridX;
  final int gridY;
  final double cellSize;

  @override
  void paint(Canvas canvas, Size size) {
    final paintFondo = Paint()..color = const Color(0x443D3D3D);
    final paintCuerpo = Paint()..color = const Color(0xFF2D6A4F);
    final paintCabeza = Paint()..color = const Color(0xFF3DDC97);
    final paintComida = Paint()..color = AppUi.acento;
    final radio = const Radius.circular(3);

    for (var y = 0; y < gridY; y++) {
      for (var x = 0; x < gridX; x++) {
        canvas.drawRRect(
          RRect.fromLTRBR(
            x * cellSize + 1,
            y * cellSize + 1,
            (x + 1) * cellSize - 1,
            (y + 1) * cellSize - 1,
            radio,
          ),
          paintFondo,
        );
      }
    }

    for (var i = 1; i < snake.length; i++) {
      final p = snake[i];
      canvas.drawRRect(
        RRect.fromLTRBR(
          p.x * cellSize + 1,
          p.y * cellSize + 1,
          (p.x + 1) * cellSize - 1,
          (p.y + 1) * cellSize - 1,
          radio,
        ),
        paintCuerpo,
      );
    }

    final cabeza = snake.first;
    canvas.drawRRect(
      RRect.fromLTRBR(
        cabeza.x * cellSize + 1,
        cabeza.y * cellSize + 1,
        (cabeza.x + 1) * cellSize - 1,
        (cabeza.y + 1) * cellSize - 1,
        radio,
      ),
      paintCabeza,
    );

    canvas.drawRRect(
      RRect.fromLTRBR(
        comida.x * cellSize + 1,
        comida.y * cellSize + 1,
        (comida.x + 1) * cellSize - 1,
        (comida.y + 1) * cellSize - 1,
        radio,
      ),
      paintComida,
    );
  }

  @override
  bool shouldRepaint(_SnakePainter old) => true;
}
