import 'package:flutter/material.dart';
import 'package:all_food/src/features/carta/data/models/producto_model.dart';
import 'package:all_food/src/features/carta/data/repositories/carta_repository.dart';
import 'package:all_food/src/features/carta/presentation/pages/producto_detalle_page.dart';
import 'package:all_food/src/shared/errors/app_error_mapper.dart';
import 'package:all_food/src/shared/widgets/logo_spinner.dart';
import 'package:all_food/src/shared/utils/error_feedback.dart';
import 'package:flutter/services.dart';

class CartaPage extends StatefulWidget {
  const CartaPage({this.initialCategoria, super.key});

  final String? initialCategoria;

  @override
  State<CartaPage> createState() => _CartaPageState();
}

class _CartaPageState extends State<CartaPage> {
  static const int _itemsPorPagina = 4;
  static const int _maxNombre = 22;
  static const int _maxDescripcion = 90;
  static const int _maxTiempo = 3;
  static const int _maxPrecio = 8;

  final _repository = CartaRepository();
  final _searchController = TextEditingController();

  String _categoria = 'todos';
  int _paginaActual = 0;
  String? _perfilUsuario;

  List<ProductoModel> _productos = [];
  bool _cargando = true;
  bool _procesandoAccion = false;
  String? _error;

  int get _totalPaginas {
    if (_productos.isEmpty) return 1;
    return (_productos.length / _itemsPorPagina).ceil();
  }

  List<ProductoModel> get _productosPagina {
    final inicio = _paginaActual * _itemsPorPagina;
    final fin = (inicio + _itemsPorPagina).clamp(0, _productos.length);
    if (inicio >= _productos.length) return const [];
    return _productos.sublist(inicio, fin);
  }

  int get _cantidadVaciosEnPagina => _itemsPorPagina - _productosPagina.length;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialCategoria;
    if (initial == 'plato' || initial == 'bebida') {
      _categoria = initial!;
    }
    _cargarPerfil();
    _cargar();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargar({String? nombre, bool mostrarSpinner = true}) async {
    if (mostrarSpinner) {
      setState(() {
        _cargando = true;
        _error = null;
      });
    } else {
      setState(() {
        _error = null;
      });
    }

    try {
      final tipo = _categoria == 'todos' ? null : _categoria;
      final data = await _repository.getProductos(tipo: tipo, nombre: nombre);

      if (!mounted) return;
      setState(() {
        _productos = data.map(ProductoModel.fromMap).toList();
        _paginaActual = 0;
        _cargando = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = AppErrorMapper.toUserMessage(
          error,
          fallbackMessage: 'Error al cargar los productos.',
        );
        _cargando = false;
      });
    }
  }

  Future<void> _cargarPerfil() async {
    try {
      final perfil = await _repository.getUserPerfil();
      if (!mounted) return;
      setState(() => _perfilUsuario = perfil);
    } catch (_) {
      if (!mounted) return;
      setState(() => _perfilUsuario = null);
    }
  }

  void _onBuscar(String valor) {
    _cargar(nombre: valor.trim().isEmpty ? null : valor.trim());
  }

  void _onCambiarCategoria(String categoria) {
    if (_categoria == categoria) return;
    setState(() {
      _categoria = categoria;
      _paginaActual = 0;
    });
    final nombre = _searchController.text.trim();
    _cargar(nombre: nombre.isEmpty ? null : nombre, mostrarSpinner: false);
  }

  void _irPaginaAnterior() {
    if (_paginaActual == 0) return;
    setState(() => _paginaActual -= 1);
  }

  void _irPaginaSiguiente() {
    if (_paginaActual >= _totalPaginas - 1) return;
    setState(() => _paginaActual += 1);
  }

  bool _puedeGestionarProducto(ProductoModel producto) {
    return (_perfilUsuario == 'cocinero' && producto.tipo == 'plato') ||
        (_perfilUsuario == 'cantinero' && producto.tipo == 'bebida');
  }

  void _mostrarMensaje(String mensaje, {required bool esError}) {
    if (esError) {
      ErrorFeedback.vibrate();
    }
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

  Future<void> _editarProducto(ProductoModel producto) async {
    final formKey = GlobalKey<FormState>();
    var nombre = producto.nombre;
    var descripcion = producto.descripcion;
    var tiempoTexto = producto.tiempoMin.toString();
    var precioTexto = producto.precio.toStringAsFixed(2);

    final payload = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) {
        final borde = OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFB77B7B)),
        );
        final foco = OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF7A2021), width: 1.5),
        );

        return Dialog(
          backgroundColor: const Color(0xFFF7ECEC),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.edit_note,
                          color: Color(0xFF7A2021),
                          size: 24,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Editar producto',
                          style: TextStyle(
                            color: Color(0xFF2A1414),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      initialValue: nombre,
                      style: const TextStyle(color: Color(0xFF2A1414)),
                      cursorColor: const Color(0xFF7A2021),
                      maxLength: _maxNombre,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(_maxNombre),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Nombre',
                        labelStyle: const TextStyle(color: Color(0xFF5D3030)),
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: borde,
                        focusedBorder: foco,
                      ),
                      validator:
                          (v) =>
                              v == null || v.trim().isEmpty
                                  ? 'Campo requerido'
                                  : null,
                      onChanged: (v) => nombre = v,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      initialValue: descripcion,
                      style: const TextStyle(color: Color(0xFF2A1414)),
                      cursorColor: const Color(0xFF7A2021),
                      maxLines: 3,
                      maxLength: _maxDescripcion,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(_maxDescripcion),
                      ],
                      decoration: InputDecoration(
                        labelText: 'DescripciÃƒÂ³n',
                        labelStyle: const TextStyle(color: Color(0xFF5D3030)),
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: borde,
                        focusedBorder: foco,
                      ),
                      validator:
                          (v) =>
                              v == null || v.trim().isEmpty
                                  ? 'Campo requerido'
                                  : null,
                      onChanged: (v) => descripcion = v,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      initialValue: tiempoTexto,
                      style: const TextStyle(color: Color(0xFF2A1414)),
                      cursorColor: const Color(0xFF7A2021),
                      keyboardType: TextInputType.number,
                      maxLength: _maxTiempo,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(_maxTiempo),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Tiempo (minutos)',
                        labelStyle: const TextStyle(color: Color(0xFF5D3030)),
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: borde,
                        focusedBorder: foco,
                      ),
                      validator:
                          (v) =>
                              int.tryParse(v ?? '') == null
                                  ? 'NÃƒÂºmero invÃƒÂ¡lido'
                                  : null,
                      onChanged: (v) => tiempoTexto = v,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      initialValue: precioTexto,
                      style: const TextStyle(color: Color(0xFF2A1414)),
                      cursorColor: const Color(0xFF7A2021),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      maxLength: _maxPrecio,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(_maxPrecio),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Precio',
                        labelStyle: const TextStyle(color: Color(0xFF5D3030)),
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: borde,
                        focusedBorder: foco,
                      ),
                      validator:
                          (v) =>
                              double.tryParse(v ?? '') == null
                                  ? 'NÃƒÂºmero invÃƒÂ¡lido'
                                  : null,
                      onChanged: (v) => precioTexto = v,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF7A2021),
                            side: const BorderSide(color: Color(0xFF7A2021)),
                            minimumSize: const Size(110, 44),
                          ),
                          child: const Text('Cancelar'),
                        ),
                        const SizedBox(width: 10),
                        FilledButton(
                          onPressed: () {
                            if (!formKey.currentState!.validate()) return;
                            Navigator.of(context).pop({
                              'nombre': nombre.trim(),
                              'descripcion': descripcion.trim(),
                              'tiempoMin': int.parse(tiempoTexto.trim()),
                              'precio': double.parse(precioTexto.trim()),
                            });
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF7A2021),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(110, 44),
                          ),
                          child: const Text('Guardar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    if (payload == null) return;

    setState(() => _procesandoAccion = true);
    try {
      await _repository.editarProducto(
        productoId: producto.id,
        tipo: producto.tipo,
        nombre: payload['nombre'] as String,
        descripcion: payload['descripcion'] as String,
        tiempoMin: payload['tiempoMin'] as int,
        precio: payload['precio'] as double,
      );
      if (!mounted) return;
      _mostrarMensaje('Producto actualizado.', esError: false);
      final nombre = _searchController.text.trim();
      await _cargar(
        nombre: nombre.isEmpty ? null : nombre,
        mostrarSpinner: false,
      );
    } catch (error) {
      if (!mounted) return;
      _mostrarMensaje(
        AppErrorMapper.toUserMessage(
          error,
          fallbackMessage: 'No se pudo editar el producto.',
        ),
        esError: true,
      );
    } finally {
      if (mounted) setState(() => _procesandoAccion = false);
    }
  }

  Future<void> _eliminarProducto(ProductoModel producto) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFFF7ECEC),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.warning_rounded,
                      color: Color(0xFFB62F2F),
                      size: 24,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Eliminar producto',
                      style: TextStyle(
                        color: Color(0xFF2A1414),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Se eliminarÃ¡ "${producto.nombre}" de la carta. Esta acciÃ³n no se puede deshacer.',
                  style: const TextStyle(
                    color: Color(0xFF3A2222),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF7A2021),
                        side: const BorderSide(color: Color(0xFF7A2021)),
                        minimumSize: const Size(110, 44),
                      ),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 10),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFB62F2F),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(110, 44),
                      ),
                      child: const Text('Eliminar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmar != true) return;

    setState(() => _procesandoAccion = true);
    try {
      await _repository.eliminarProducto(
        productoId: producto.id,
        tipo: producto.tipo,
      );
      if (!mounted) return;
      _mostrarMensaje('Producto eliminado de la carta.', esError: false);
      final nombre = _searchController.text.trim();
      await _cargar(
        nombre: nombre.isEmpty ? null : nombre,
        mostrarSpinner: false,
      );
    } catch (error) {
      if (!mounted) return;
      _mostrarMensaje(
        AppErrorMapper.toUserMessage(
          error,
          fallbackMessage: 'No se pudo eliminar el producto.',
        ),
        esError: true,
      );
    } finally {
      if (mounted) setState(() => _procesandoAccion = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Carta de productos')),
      body: Container(
        color: const Color(0xFF5A0F10),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _searchController,
                onChanged: _onBuscar,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF9D2A2A),
                  hintText: 'Buscar por nombre...',
                  hintStyle: const TextStyle(color: Color(0xFFFFD6D6)),
                  prefixIcon: const Icon(Icons.search, color: Colors.white),
                  suffixIcon:
                      _searchController.text.isNotEmpty
                          ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white),
                            onPressed: () {
                              _searchController.clear();
                              _onBuscar('');
                            },
                          )
                          : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFFFC2C2)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFFFC2C2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: Colors.white,
                      width: 1.8,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Todos'),
                    selected: _categoria == 'todos',
                    onSelected: (_) => _onCambiarCategoria('todos'),
                    selectedColor: const Color(0xFFF8D9D9),
                    backgroundColor: const Color(0xFFF2ECEC),
                    checkmarkColor: const Color(0xFF4A1414),
                    side: const BorderSide(color: Color(0xFFD8BBBB)),
                    labelStyle: const TextStyle(
                      color: Color(0xFF4A1414),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  ChoiceChip(
                    label: const Text('Platos'),
                    selected: _categoria == 'plato',
                    onSelected: (_) => _onCambiarCategoria('plato'),
                    selectedColor: const Color(0xFFF8D9D9),
                    backgroundColor: const Color(0xFFF2ECEC),
                    checkmarkColor: const Color(0xFF4A1414),
                    side: const BorderSide(color: Color(0xFFD8BBBB)),
                    labelStyle: const TextStyle(
                      color: Color(0xFF4A1414),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  ChoiceChip(
                    label: const Text('Bebidas'),
                    selected: _categoria == 'bebida',
                    onSelected: (_) => _onCambiarCategoria('bebida'),
                    selectedColor: const Color(0xFFF8D9D9),
                    backgroundColor: const Color(0xFFF2ECEC),
                    checkmarkColor: const Color(0xFF4A1414),
                    side: const BorderSide(color: Color(0xFFD8BBBB)),
                    labelStyle: const TextStyle(
                      color: Color(0xFF4A1414),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child:
                  _cargando
                      ? const Center(
                        child: LogoSpinner(size: 60, strokeWidth: 4),
                      )
                      : _error != null
                      ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _error!,
                              style: const TextStyle(color: Colors.white70),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF2D6A4F),
                              ),
                              onPressed: () => _cargar(),
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      )
                      : _productos.isEmpty
                      ? const Center(
                        child: Text(
                          'No hay productos disponibles.',
                          style: TextStyle(color: Colors.white70),
                        ),
                      )
                      : Column(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                              child: Column(
                                children: List.generate(_itemsPorPagina, (
                                  index,
                                ) {
                                  final tieneProducto =
                                      index < _productosPagina.length;
                                  final esUltimoSlot =
                                      index == _itemsPorPagina - 1;

                                  return Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        bottom: esUltimoSlot ? 0 : 4,
                                      ),
                                      child:
                                          tieneProducto
                                              ? Builder(
                                                builder: (context) {
                                                  final producto =
                                                      _productosPagina[index];
                                                  final puedeGestionar =
                                                      _puedeGestionarProducto(
                                                        producto,
                                                      ) &&
                                                      !_procesandoAccion;
                                                  return _ProductoCard(
                                                    producto: producto,
                                                    onTap: () {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder:
                                                              (
                                                                _,
                                                              ) => ProductoDetallePage(
                                                                producto:
                                                                    producto,
                                                                onEditar:
                                                                    puedeGestionar
                                                                        ? () => _editarProducto(
                                                                          producto,
                                                                        )
                                                                        : null,
                                                                onEliminar:
                                                                    puedeGestionar
                                                                        ? () => _eliminarProducto(
                                                                          producto,
                                                                        )
                                                                        : null,
                                                              ),
                                                        ),
                                                      );
                                                    },
                                                  );
                                                },
                                              )
                                              : _SlotVacioProducto(
                                                mostrarMensaje:
                                                    _cantidadVaciosEnPagina >
                                                        0 &&
                                                    index ==
                                                        _productosPagina.length,
                                              ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                            child: Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed:
                                        _paginaActual == 0
                                            ? null
                                            : _irPaginaAnterior,
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size.fromHeight(46),
                                      foregroundColor: const Color(0xFF4A0E10),
                                      backgroundColor: Colors.white,
                                      disabledForegroundColor: Colors.white54,
                                      disabledBackgroundColor: const Color(
                                        0xFF7A2021,
                                      ),
                                      side: const BorderSide(
                                        color: Colors.white,
                                        width: 1.4,
                                      ),
                                      textStyle: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                    icon: const Icon(Icons.chevron_left),
                                    label: const Text('Anterior'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'PÃƒÂ¡gina ${_paginaActual + 1} / $_totalPaginas',
                                  style: const TextStyle(
                                    color: Color(0xFFFFE9E9),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed:
                                        _paginaActual >= _totalPaginas - 1
                                            ? null
                                            : _irPaginaSiguiente,
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size.fromHeight(46),
                                      foregroundColor: const Color(0xFF4A0E10),
                                      backgroundColor: Colors.white,
                                      disabledForegroundColor: Colors.white54,
                                      disabledBackgroundColor: const Color(
                                        0xFF7A2021,
                                      ),
                                      side: const BorderSide(
                                        color: Colors.white,
                                        width: 1.4,
                                      ),
                                      textStyle: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                    icon: const Icon(Icons.chevron_right),
                                    label: const Text('Siguiente'),
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
    );
  }
}

class _ProductoCard extends StatelessWidget {
  const _ProductoCard({required this.producto, required this.onTap});

  final ProductoModel producto;
  final VoidCallback onTap;

  static String _limitarTexto(String value, int maxChars) {
    final limpio = value.trim();
    if (maxChars <= 1) return limpio.isEmpty ? '' : 'Ã¢â‚¬Â¦';
    if (limpio.length <= maxChars) return limpio;
    return '${limpio.substring(0, maxChars - 1)}Ã¢â‚¬Â¦';
  }

  @override
  Widget build(BuildContext context) {
    final esPlato = producto.tipo == 'plato';
    final nombre = _limitarTexto(producto.nombre, 18);
    final descripcion = _limitarTexto(producto.descripcion, 34);
    final tipo = _limitarTexto(esPlato ? 'Plato' : 'Bebida', 8);
    final tiempo = _limitarTexto(producto.tiempoMin.toString(), 10);
    final precio = _limitarTexto(producto.precio.toStringAsFixed(2), 10);

    return Card(
      color: const Color(0xFFA02C2C),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFFFC9C9), width: 0.6),
      ),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  producto.foto1,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (_, __, ___) => Container(
                        width: 64,
                        height: 64,
                        color: Colors.white12,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.broken_image,
                          color: Colors.white54,
                        ),
                      ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      descripcion,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFFFDDDD),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: _DatoPildora(
                            icon: esPlato ? Icons.restaurant : Icons.local_bar,
                            text: tipo,
                            centered: true,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: _DatoPildora(
                            icon: Icons.access_time,
                            text: tiempo,
                            centered: true,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: _DatoPildora(
                            icon: Icons.attach_money,
                            text: precio,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.chevron_right, color: Colors.white70),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Toca para ver/editar detalles',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xFFFFD6D6),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DatoPildora extends StatelessWidget {
  const _DatoPildora({
    required this.icon,
    required this.text,
    this.centered = false,
  });

  final IconData icon;
  final String text;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF9A3A3A),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFFFB9B9)),
      ),
      child: Row(
        mainAxisAlignment:
            centered ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          Icon(icon, size: 12, color: Colors.white70),
          const SizedBox(width: 2),
          if (centered)
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SlotVacioProducto extends StatelessWidget {
  const _SlotVacioProducto({required this.mostrarMensaje});

  final bool mostrarMensaje;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF8D2628).withOpacity(0.38),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      alignment: Alignment.center,
      child:
          mostrarMensaje
              ? const Text(
                'No hay mÃƒÂ¡s productos',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              )
              : const SizedBox.shrink(),
    );
  }
}
