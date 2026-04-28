import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:all_food/src/features/mesas/data/repositories/mesas_repository.dart';
import 'package:all_food/src/shared/errors/app_error_mapper.dart';
import 'package:all_food/src/shared/widgets/logo_spinner.dart';
import 'package:all_food/src/shared/utils/error_feedback.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

class VerEditarMesasPage extends StatefulWidget {
  const VerEditarMesasPage({required this.supabaseReady, super.key});

  final bool supabaseReady;

  @override
  State<VerEditarMesasPage> createState() => _VerEditarMesasPageState();
}

class _VerEditarMesasPageState extends State<VerEditarMesasPage> {
  final _repository = MesasRepository();
  final _pageController = PageController(viewportFraction: 1.0);

  bool _cargando = true;
  bool _puedeGestionar = false;
  List<_MesaDraft> _mesas = [];

  @override
  void initState() {
    super.initState();
    _cargarTodo();
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final mesa in _mesas) {
      mesa.dispose();
    }
    super.dispose();
  }

  void _sortMesasByNumber() {
    _mesas.sort((a, b) => a.numeroActual.compareTo(b.numeroActual));
  }

  Future<void> _cargarTodo() async {
    if (!widget.supabaseReady) {
      setState(() {
        _cargando = false;
        _puedeGestionar = false;
      });
      return;
    }

    try {
      final autorizado = await _repository.canCurrentUserManageTables();
      if (!mounted) return;

      if (!autorizado) {
        setState(() {
          _cargando = false;
          _puedeGestionar = false;
        });
        return;
      }

      final mesas = await _repository.getTables();
      if (!mounted) return;

      for (final mesa in _mesas) {
        mesa.dispose();
      }

      final drafts = mesas.map(_MesaDraft.fromMap).toList();
      drafts.sort((a, b) => a.numeroActual.compareTo(b.numeroActual));

      setState(() {
        _cargando = false;
        _puedeGestionar = true;
        _mesas = drafts;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _puedeGestionar = false;
      });
    }
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

  Future<void> _guardarCambios(_MesaDraft mesa) async {
    if (mesa.guardando || !mesa.editando) return;

    final numero = int.tryParse(mesa.numeroController.text.trim());
    final lugares = int.tryParse(mesa.comensalesController.text.trim());

    if (numero == null || numero <= 0) {
      _mostrarMensaje(
        'El numero de mesa debe ser un entero positivo.',
        esError: true,
      );
      return;
    }

    if (lugares == null || lugares <= 0) {
      _mostrarMensaje(
        'La cantidad de comensales debe ser un entero positivo.',
        esError: true,
      );
      return;
    }

    setState(() => mesa.guardando = true);

    try {
      await _repository.updateTable(
        mesaId: mesa.id,
        numeroMesa: numero,
        cantidadComensales: lugares,
        tipoMesa: mesa.tipo,
      );

      mesa.markSaved(numero: numero, lugares: lugares, tipo: mesa.tipo);
      mesa.editando = false;

      if (!mounted) return;
      setState(_sortMesasByNumber);
      _mostrarMensaje('Mesa actualizada correctamente.', esError: false);
    } catch (error) {
      _mostrarMensaje(
        AppErrorMapper.toUserMessage(
          error,
          fallbackMessage: 'No se pudo actualizar la mesa.',
        ),
        esError: true,
      );
    } finally {
      if (mounted) {
        setState(() => mesa.guardando = false);
      }
    }
  }

  Future<void> _eliminarMesa(_MesaDraft mesa) async {
    if (mesa.eliminando) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFFFFF7EF),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Eliminar mesa',
                  style: TextStyle(
                    color: Color(0xFF2A1414),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Se eliminará la mesa ${mesa.numeroController.text.trim()}. Esta acción no se puede deshacer.',
                  style: const TextStyle(
                    color: Color(0xFF3A2222),
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF6E3B3B),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 10),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFB62F2F),
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
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

    if (confirmar != true || !mounted) return;

    setState(() => mesa.eliminando = true);

    try {
      await _repository.deleteTable(mesa.id);
      if (!mounted) return;

      setState(() {
        _mesas.removeWhere((item) => item.id == mesa.id);
        _sortMesasByNumber();
      });

      mesa.dispose();
      _mostrarMensaje('Mesa eliminada correctamente.', esError: false);
    } catch (error) {
      if (!mounted) return;
      _mostrarMensaje(
        AppErrorMapper.toUserMessage(
          error,
          fallbackMessage: 'No se pudo eliminar la mesa.',
        ),
        esError: true,
      );
      setState(() => mesa.eliminando = false);
    }
  }

  Future<void> _mostrarQrMesa(_MesaDraft mesa) async {
    final qrCodigo = mesa.qrCodigo?.trim() ?? '';

    if (qrCodigo.isEmpty) {
      _mostrarMensaje('La mesa no tiene un QR generado.', esError: true);
      return;
    }

    final qrBytes = await _generarQrComoPng(qrCodigo);

    await showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF2A1414),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'QR de mesa',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 28,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Mesa ${mesa.numeroController.text.trim()}',
                  style: const TextStyle(
                    color: Color(0xFFFFE8C2),
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(10),
                  child:
                      qrBytes != null
                          ? Image.memory(
                            qrBytes,
                            width: 190,
                            height: 190,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.none,
                          )
                          : QrImageView(
                            data: qrCodigo,
                            version: QrVersions.auto,
                            size: 190,
                            backgroundColor: Colors.white,
                          ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A2222),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF6E3B3B)),
                  ),
                  child: SelectableText(
                    qrCodigo,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFFFE8C2),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF7A2021),
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cerrar'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<Uint8List?> _generarQrComoPng(String qrCodigo) async {
    try {
      final painter = QrPainter(
        data: qrCodigo,
        version: QrVersions.auto,
        color: Colors.black,
        emptyColor: Colors.white,
        gapless: false,
      );

      final imageData = await painter.toImageData(
        512,
        format: ui.ImageByteFormat.png,
      );

      return imageData?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(
        body: Center(child: LogoSpinner(size: 88, strokeWidth: 6)),
      );
    }

    if (!_puedeGestionar) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ver / editar mesas')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Acceso denegado. Esta funcionalidad esta disponible para dueno, supervisor y metre habilitados.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ver / editar mesas'),
        actions: [
          IconButton(
            onPressed: _cargarTodo,
            icon: const Icon(Icons.refresh),
            tooltip: 'Recargar',
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF5B1718), Color(0xFF7A2021)],
          ),
        ),
        child: SafeArea(
          child:
              _mesas.isEmpty
                  ? const Center(
                    child: Text(
                      'No hay mesas registradas.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                  : Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(18, 14, 18, 6),
                        child: Text(
                          'Desliza verticalmente para navegar las mesas',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          scrollDirection: Axis.vertical,
                          itemCount: _mesas.length,
                          itemBuilder: (context, index) {
                            final mesa = _mesas[index];
                            return Padding(
                              padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                              child: _MesaEditorCard(
                                mesa: mesa,
                                index: index,
                                total: _mesas.length,
                                onChanged: () => setState(() {}),
                                onGuardar: () => _guardarCambios(mesa),
                                onEditar: () {
                                  mesa.editando = true;
                                  setState(() {});
                                },
                                onCancelar: () {
                                  mesa.restoreOriginalValues();
                                  mesa.editando = false;
                                  setState(() {});
                                },
                                onEliminar: () => _eliminarMesa(mesa),
                                onVerQr: () => _mostrarQrMesa(mesa),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
        ),
      ),
    );
  }
}

class _MesaEditorCard extends StatelessWidget {
  const _MesaEditorCard({
    required this.mesa,
    required this.index,
    required this.total,
    required this.onChanged,
    required this.onGuardar,
    required this.onEditar,
    required this.onCancelar,
    required this.onEliminar,
    required this.onVerQr,
  });

  final _MesaDraft mesa;
  final int index;
  final int total;
  final VoidCallback onChanged;
  final VoidCallback onGuardar;
  final VoidCallback onEditar;
  final VoidCallback onCancelar;
  final VoidCallback onEliminar;
  final VoidCallback onVerQr;

  @override
  Widget build(BuildContext context) {
    const textDark = Color(0xFFFFE6E6);
    const softBorder = Color(0xFF9A6C72);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF241519),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF8F5F64), width: 1),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          inputDecorationTheme: const InputDecorationTheme(
            labelStyle: TextStyle(color: Color(0xFFFFD0D0)),
            filled: true,
            fillColor: Color(0xFF311E23),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: softBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFFFAEB5), width: 1.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: softBorder),
            ),
            border: OutlineInputBorder(),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Mesa ${index + 1} de $total',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFFFCACA)),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed:
                        mesa.guardando || mesa.eliminando || mesa.editando
                            ? null
                            : onEditar,
                    tooltip: 'Editar mesa',
                    style: IconButton.styleFrom(
                      backgroundColor:
                          mesa.editando
                              ? const Color(0xFF2D6A4F)
                              : const Color(0xFFE8F5EE),
                      minimumSize: const Size(56, 56),
                      padding: const EdgeInsets.all(14),
                    ),
                    icon: Icon(
                      Icons.edit,
                      size: 28,
                      color:
                          mesa.editando
                              ? Colors.white
                              : const Color(0xFF2D6A4F),
                    ),
                  ),
                  if (mesa.editando) const SizedBox(width: 8),
                  if (mesa.editando)
                    OutlinedButton.icon(
                      onPressed:
                          mesa.guardando || mesa.eliminando ? null : onCancelar,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF7A2021),
                        backgroundColor: const Color(0xFFFFF4F4),
                        side: const BorderSide(
                          color: Color(0xFF7A2021),
                          width: 1.4,
                        ),
                        minimumSize: const Size(126, 52),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      icon: const Icon(Icons.close, size: 22),
                      label: const Text('Cancelar'),
                    ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed:
                        mesa.guardando || mesa.eliminando ? null : onVerQr,
                    tooltip: 'Ver QR de mesa',
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFE9EFFA),
                      minimumSize: const Size(56, 56),
                      padding: const EdgeInsets.all(14),
                    ),
                    icon: const Icon(
                      Icons.qr_code_2,
                      size: 28,
                      color: Color(0xFF1C4B8F),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed:
                        mesa.guardando || mesa.eliminando ? null : onEliminar,
                    tooltip: 'Eliminar mesa',
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFFFE8E8),
                      minimumSize: const Size(56, 56),
                      padding: const EdgeInsets.all(14),
                    ),
                    icon:
                        mesa.eliminando
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: LogoSpinner(size: 20, strokeWidth: 2),
                            )
                            : const Icon(
                              Icons.delete,
                              size: 28,
                              color: Color(0xFFB42318),
                            ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Datos de mesa',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'ArchivoBlack',
                  fontSize: 30,
                  color: Color(0xFFFFD9DC),
                  letterSpacing: -1.2,
                ),
              ),
              if (!mesa.editando) const SizedBox(height: 30),
              if (mesa.fotoUrl != null && mesa.fotoUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    mesa.fotoUrl!,
                    height: 230,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                      return Container(
                        height: 230,
                        color: const Color(0xFF3A252A),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.broken_image,
                          color: Color(0xFFD7B1B4),
                        ),
                      );
                    },
                  ),
                )
              else
                Container(
                  height: 230,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A252A),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.table_restaurant,
                    size: 40,
                    color: Color(0xFFD7B1B4),
                  ),
                ),
              if (!mesa.editando) const SizedBox(height: 56),
              if (mesa.editando) const SizedBox(height: 18),
              if (mesa.editando) ...[
                TextFormField(
                  controller: mesa.numeroController,
                  style: const TextStyle(color: textDark),
                  enabled: mesa.editando,
                  readOnly: !mesa.editando,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: mesa.editando ? (_) => onChanged() : null,
                  decoration: const InputDecoration(
                    labelText: 'Numero de mesa',
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: mesa.comensalesController,
                  style: const TextStyle(color: textDark),
                  enabled: mesa.editando,
                  readOnly: !mesa.editando,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: mesa.editando ? (_) => onChanged() : null,
                  decoration: const InputDecoration(
                    labelText: 'Cantidad de comensales',
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: mesa.tipo,
                  dropdownColor: const Color(0xFF311E23),
                  style: const TextStyle(color: textDark),
                  decoration: const InputDecoration(labelText: 'Tipo de mesa'),
                  items: const [
                    DropdownMenuItem(value: 'vip', child: Text('VIP')),
                    DropdownMenuItem(
                      value: 'estandar',
                      child: Text('Estandar'),
                    ),
                    DropdownMenuItem(
                      value: 'movilidad_reducida',
                      child: Text('Movilidad reducida'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    mesa.tipo = value;
                    onChanged();
                  },
                ),
              ],
              if (!mesa.editando)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF331F24),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF8F5F64)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _MesaInfoTile(
                              icon: Icons.pin_outlined,
                              label: 'Numero',
                              value: mesa.numeroController.text,
                              backgroundColor: const Color(0xFF432A30),
                              borderColor: const Color(0xFF9C6D73),
                              iconColor: const Color(0xFFFFB7BD),
                              labelColor: const Color(0xFFE6BEC1),
                              valueColor: const Color(0xFFFFEDEE),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _MesaInfoTile(
                              icon: Icons.people_alt_outlined,
                              label: 'Comensales',
                              value: mesa.comensalesController.text,
                              backgroundColor: const Color(0xFF432A30),
                              borderColor: const Color(0xFF9C6D73),
                              iconColor: const Color(0xFFFFB7BD),
                              labelColor: const Color(0xFFE6BEC1),
                              valueColor: const Color(0xFFFFEDEE),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _MesaInfoTile(
                        icon: Icons.category_outlined,
                        label: 'Tipo de mesa',
                        value: mesa.tipoTexto,
                        fullWidth: true,
                        backgroundColor: const Color(0xFF432A30),
                        borderColor: const Color(0xFF9C6D73),
                        iconColor: const Color(0xFFFFB7BD),
                        labelColor: const Color(0xFFE6BEC1),
                        valueColor: const Color(0xFFFFEDEE),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 14),
              if (mesa.editando)
                FilledButton.icon(
                  onPressed:
                      mesa.guardando || !mesa.hasChanges ? null : onGuardar,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                    backgroundColor: const Color(0xFF2D6A4F),
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(
                      fontFamily: 'ArchivoBlack',
                      fontSize: 17,
                      letterSpacing: 0.3,
                    ),
                  ),
                  icon:
                      mesa.guardando
                          ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: LogoSpinner(size: 18, strokeWidth: 2),
                          )
                          : const Icon(Icons.save),
                  label: Text(
                    mesa.hasChanges ? 'Guardar cambios' : 'Sin cambios',
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MesaInfoTile extends StatelessWidget {
  const _MesaInfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.fullWidth = false,
    this.backgroundColor = Colors.white,
    this.borderColor = const Color(0xFFE5E7EB),
    this.iconColor = const Color(0xFF7A2021),
    this.labelColor = const Color(0xFF6B7280),
    this.valueColor = const Color(0xFF1F2937),
  });

  final IconData icon;
  final String label;
  final String value;
  final bool fullWidth;
  final Color backgroundColor;
  final Color borderColor;
  final Color iconColor;
  final Color labelColor;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: labelColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    color: valueColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MesaDraft {
  _MesaDraft({
    required this.id,
    required int numero,
    required int cantidadLugares,
    required this.tipo,
    this.fotoUrl,
    this.qrCodigo,
  }) : _originalNumero = numero,
       _originalLugares = cantidadLugares,
       _originalTipo = tipo,
       numeroController = TextEditingController(text: numero.toString()),
       comensalesController = TextEditingController(
         text: cantidadLugares.toString(),
       );

  factory _MesaDraft.fromMap(Map<String, dynamic> data) {
    return _MesaDraft(
      id: data['id'] as String,
      numero: (data['numero'] as num).toInt(),
      cantidadLugares: (data['cantidad_lugares'] as num).toInt(),
      tipo: data['tipo'] as String,
      fotoUrl: data['foto_url'] as String?,
      qrCodigo: data['qr_codigo'] as String?,
    );
  }

  final String id;
  final String? fotoUrl;
  final String? qrCodigo;

  final TextEditingController numeroController;
  final TextEditingController comensalesController;

  String tipo;
  bool editando = false;
  bool guardando = false;
  bool eliminando = false;

  int _originalNumero;
  int _originalLugares;
  String _originalTipo;

  String get tipoTexto {
    if (tipo == 'vip') return 'VIP';
    if (tipo == 'movilidad_reducida') return 'Movilidad reducida';
    return 'Estandar';
  }

  bool get hasChanges {
    final numero = int.tryParse(numeroController.text.trim());
    final lugares = int.tryParse(comensalesController.text.trim());

    return numero != _originalNumero ||
        lugares != _originalLugares ||
        tipo != _originalTipo;
  }

  int get numeroActual {
    return int.tryParse(numeroController.text.trim()) ?? _originalNumero;
  }

  void markSaved({
    required int numero,
    required int lugares,
    required String tipo,
  }) {
    _originalNumero = numero;
    _originalLugares = lugares;
    _originalTipo = tipo;

    numeroController.text = numero.toString();
    comensalesController.text = lugares.toString();
    this.tipo = tipo;
  }

  void restoreOriginalValues() {
    numeroController.text = _originalNumero.toString();
    comensalesController.text = _originalLugares.toString();
    tipo = _originalTipo;
  }

  void dispose() {
    numeroController.dispose();
    comensalesController.dispose();
  }
}
