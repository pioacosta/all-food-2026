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
          fallbackMessage: 'No se pudo cargar la secci\u00F3n de juegos.',
        ),
        esError: true,
      );
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  String _keyIntento({required int porcentaje}) {
    return 'juego_${widget.pedidoId}_$porcentaje';
  }

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

    final eleccion = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: AppUi.panel,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Juego 10%: adivin\u00E1 el n\u00FAmero',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(
                    6,
                    (index) => ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(index + 1),
                      child: Text('${index + 1}'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
          'Ganaste, pero ya ten\u00EDas un descuento del ${_descuentoAplicado.toStringAsFixed(0)}%.',
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
          '\u00A1Ganaste! Se aplic\u00F3 $porcentaje% a la cuenta final.',
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
    if (esError) {
      ErrorFeedback.vibrate();
    }
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: esError ? AppUi.error : AppUi.exito,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Juegos y descuentos')),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: AppUi.fondoPrincipal),
        child: SafeArea(
          child:
              _cargando
                  ? const Center(child: LogoSpinner(size: 70, strokeWidth: 4))
                  : Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: AppUi.panelDecoracion(radius: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Reglas de beneficios',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Si gan\u00E1s en el primer intento del juego, pod\u00E9s obtener el descuento. El descuento no se acumula.',
                                style: TextStyle(color: AppUi.textoSecundario),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _descuentoAplicado > 0
                                    ? 'Descuento activo: ${_descuentoAplicado.toStringAsFixed(0)}%'
                                    : 'A\u00FAn no hay descuento aplicado.',
                                style: const TextStyle(
                                  color: AppUi.acento,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: ListView(
                            children: [
                              _JuegoCard(
                                titulo: 'Juego 1 - Adivinar n\u00FAmero (10%)',
                                descripcion:
                                    'Eleg\u00ED un n\u00FAmero del 1 al 6. Si coincide, gan\u00E1s.',
                                intentoUsado: _intentoConsumido[10] == true,
                                onPlay: _procesando ? null : _jugarNumero10,
                              ),
                              const SizedBox(height: 10),
                              _JuegoCard(
                                titulo: 'Juego 2 - Comidas y bombas (15%)',
                                descripcion:
                                    'Toc\u00E1 comidas para sumar y evit\u00E1 bombas que restan. Necesit\u00E1s 120 puntos.',
                                intentoUsado: _intentoConsumido[15] == true,
                                onPlay: _procesando ? null : _jugarComidas15,
                              ),
                              const SizedBox(height: 10),
                              _JuegoCard(
                                titulo: 'Juego 3 - Snake cl\u00E1sico (20%)',
                                descripcion:
                                    'Com\u00E9 15 veces sin perder para ganar el descuento.',
                                intentoUsado: _intentoConsumido[20] == true,
                                onPlay: _procesando ? null : _jugarSnake20,
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

class _JuegoCard extends StatelessWidget {
  const _JuegoCard({
    required this.titulo,
    required this.descripcion,
    required this.intentoUsado,
    required this.onPlay,
  });

  final String titulo;
  final String descripcion;
  final bool intentoUsado;
  final VoidCallback? onPlay;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppUi.panelDecoracion(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            descripcion,
            style: const TextStyle(color: AppUi.textoSecundario),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onPlay,
              icon: Icon(intentoUsado ? Icons.refresh : Icons.play_arrow),
              label: Text(
                intentoUsado ? 'Rejugar (sin descuento)' : 'Jugar ahora',
              ),
            ),
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
  static const int _grid = 14;
  static const int _metaComidas = 15;

  final _random = Random();
  final List<Point<int>> _snake = [
    const Point(7, 7),
    const Point(6, 7),
    const Point(5, 7),
  ];
  _DireccionSnake _direccion = _DireccionSnake.derecha;
  Timer? _timer;
  Point<int> _comida = const Point(10, 7);
  bool _terminado = false;
  bool _gano = false;
  int _comidas = 0;

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
      final nueva = Point(_random.nextInt(_grid), _random.nextInt(_grid));
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
    _direccion = nueva;
  }

  void _tick() {
    if (!mounted || _terminado) return;

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
        nuevaCabeza.x >= _grid ||
        nuevaCabeza.y >= _grid;
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
      appBar: AppBar(title: const Text('Snake cl\u00E1sico')),
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
                          'Comidas: $_comidas / $_metaComidas',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        _terminado
                            ? (_gano ? '\u00A1Ganaste!' : 'Perdiste')
                            : 'En juego',
                        style: const TextStyle(color: AppUi.acento),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(8),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: _grid,
                              crossAxisSpacing: 1,
                              mainAxisSpacing: 1,
                            ),
                        itemCount: _grid * _grid,
                        itemBuilder: (context, index) {
                          final x = index % _grid;
                          final y = index ~/ _grid;
                          final p = Point(x, y);
                          final esCabeza = p == _snake.first;
                          final esCuerpo = _snake.contains(p);
                          final esComida = p == _comida;

                          Color color = const Color(0x443D3D3D);
                          if (esComida) {
                            color = AppUi.acento;
                          } else if (esCabeza) {
                            color = const Color(0xFF3DDC97);
                          } else if (esCuerpo) {
                            color = const Color(0xFF2D6A4F);
                          }

                          return Container(
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _PadControles(onDireccion: _cambiarDireccion),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PadControles extends StatelessWidget {
  const _PadControles({required this.onDireccion});

  final ValueChanged<_DireccionSnake> onDireccion;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton(
          onPressed: () => onDireccion(_DireccionSnake.arriba),
          icon: const Icon(Icons.keyboard_arrow_up, color: Colors.white),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: () => onDireccion(_DireccionSnake.izquierda),
              icon: const Icon(Icons.keyboard_arrow_left, color: Colors.white),
            ),
            const SizedBox(width: 28),
            IconButton(
              onPressed: () => onDireccion(_DireccionSnake.derecha),
              icon: const Icon(Icons.keyboard_arrow_right, color: Colors.white),
            ),
          ],
        ),
        IconButton(
          onPressed: () => onDireccion(_DireccionSnake.abajo),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
        ),
      ],
    );
  }
}
