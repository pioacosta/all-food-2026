import 'dart:io';

import 'package:all_food/src/features/mesas/data/services/mesas_service.dart';
import 'package:all_food/src/shared/services/notificaciones_service.dart';
import 'package:all_food/src/shared/errors/app_exception.dart';

class MesasFlowException extends AppException {
  const MesasFlowException(super.message);
}

// Reglas de negocio de mesas y atención en salón.
// Este repositorio aplica validaciones de permisos, estados y notificaciones.
class MesasRepository {
  MesasRepository({MesasService? service})
    : _service = service ?? MesasService();

  final MesasService _service;
  final NotificacionesService _notificacionesService = NotificacionesService();

  // ----- Permisos por rol -----
  Future<bool> canCurrentUserCreateTables() async {
    final profile = await _service.getCurrentUserProfile();
    final rol = (profile['perfil'] as String?) ?? '';
    final habilitado = profile['habilitado'] == true;

    return habilitado && (rol == 'dueno' || rol == 'supervisor');
  }

  Future<bool> canCurrentUserManageTables() async {
    final profile = await _service.getCurrentUserProfile();
    final rol = (profile['perfil'] as String?) ?? '';
    final habilitado = profile['habilitado'] == true;

    return habilitado &&
        (rol == 'dueno' || rol == 'supervisor' || rol == 'metre');
  }

  Future<bool> tableNumberExists(int numeroMesa) {
    return _service.tableNumberExists(numeroMesa);
  }

  Future<bool> tableNumberExistsForOther({
    required int numeroMesa,
    required String mesaId,
  }) {
    return _service.tableNumberExistsForOther(
      numeroMesa: numeroMesa,
      mesaId: mesaId,
    );
  }

  Future<List<Map<String, dynamic>>> getTables() {
    return _service.fetchTables();
  }

  Future<String> uploadTablePhoto(File photo) async {
    final uid = _service.currentUserId;
    if (uid == null) {
      throw const MesasFlowException('No hay un usuario autenticado.');
    }

    final millis = DateTime.now().millisecondsSinceEpoch;
    final path = '$uid/mesa_$millis.jpg';

    await _service.uploadTablePhoto(path: path, photo: photo);
    return _service.getTablePhotoPublicUrl(path);
  }

  Future<String> createTable({
    required int numeroMesa,
    required int cantidadComensales,
    required String tipoMesa,
    required String fotoUrl,
  }) async {
    final exists = await _service.tableNumberExists(numeroMesa);
    if (exists) {
      throw const MesasFlowException('Ya existe una mesa con ese número.');
    }

    final qrCode = _buildQrCode(numeroMesa);

    await _service.insertTable({
      'numero': numeroMesa,
      'cantidad_lugares': cantidadComensales,
      'tipo': tipoMesa,
      'foto_url': fotoUrl,
      'qr_codigo': qrCode,
      'ocupada': false,
    });

    return qrCode;
  }

  Future<void> updateTable({
    required String mesaId,
    required int numeroMesa,
    required int cantidadComensales,
    required String tipoMesa,
  }) async {
    final exists = await _service.tableNumberExistsForOther(
      numeroMesa: numeroMesa,
      mesaId: mesaId,
    );

    if (exists) {
      throw const MesasFlowException('Ya existe una mesa con ese número.');
    }

    await _service.updateTable(
      mesaId: mesaId,
      payload: {
        'numero': numeroMesa,
        'cantidad_lugares': cantidadComensales,
        'tipo': tipoMesa,
      },
    );
  }

  Future<void> deleteTable(String mesaId) {
    return _service.deleteTable(mesaId);
  }

  String _buildQrCode(int numeroMesa) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    return 'MESA-$numeroMesa-$ts';
  }

  Future<Map<String, dynamic>> validarAccesoClientePorQrMesa(
    String qrCodigo,
  ) async {
    // El cliente solo puede operar sobre su mesa asignada por el metre.
    final clienteId = _service.currentUserId;
    if (clienteId == null) {
      throw const MesasFlowException('No hay un usuario autenticado.');
    }

    final mesa = await _service.getMesaByQrCodigo(qrCodigo.trim());
    if (mesa == null) {
      throw const MesasFlowException('El QR no corresponde a una mesa válida.');
    }

    final clienteAsignado = mesa['cliente_id'] as String?;
    if (clienteAsignado == null) {
      throw const MesasFlowException(
        'La mesa no tiene un cliente asignado. Solicita asignación al metre.',
      );
    }

    if (clienteAsignado != clienteId) {
      throw const MesasFlowException(
        'No puedes ingresar con este QR. Esta mesa está asignada a otro cliente.',
      );
    }

    return mesa;
  }

  Future<Map<String, dynamic>> getEstadoMesaClienteActual() async {
    final clienteId = _service.currentUserId;
    if (clienteId == null) {
      throw const MesasFlowException('No hay un usuario autenticado.');
    }

    final mesa = await _service.getMesaByClienteId(clienteId);
    if (mesa != null) {
      return {'estado': 'mesa_asignada', 'mesa': mesa};
    }

    final solicitud = await _service.getPendienteSolicitudMesaByCliente(
      clienteId,
    );
    if (solicitud != null) {
      return {'estado': 'esperando_metre', 'solicitud': solicitud};
    }

    return {'estado': 'sin_solicitud'};
  }

  Future<void> solicitarMesaClienteActual() async {
    final clienteId = _service.currentUserId;
    if (clienteId == null) {
      throw const MesasFlowException('No hay un usuario autenticado.');
    }

    final mesa = await _service.getMesaByClienteId(clienteId);
    if (mesa != null) {
      throw const MesasFlowException('Ya tienes una mesa asignada.');
    }

    final pendiente = await _service.getPendienteSolicitudMesaByCliente(
      clienteId,
    );
    if (pendiente != null) {
      throw const MesasFlowException(
        'Ya solicitaste una mesa. Espera la asignación del metre.',
      );
    }

    final perfil = await _service.getProfileById(clienteId);

    await _service.createSolicitudMesa(
      clienteId: clienteId,
      nombres: (perfil['nombres'] as String?) ?? 'Cliente',
      apellidos: perfil['apellidos'] as String?,
      perfil: (perfil['perfil'] as String?) ?? 'cliente_registrado',
      fotoUrl: perfil['foto_url'] as String?,
    );

    await _notificarPorPerfiles(
      perfiles: const ['metre', 'dueno', 'supervisor'],
      titulo: 'Nueva solicitud de mesa',
      mensaje:
          'Un cliente se registró en la lista de espera y solicita asignación.',
      tipo: 'solicitud_mesa',
      payload: {'clienteId': clienteId},
    );
  }

  Future<void> enviarConsultaRapidaMozo({
    required String mesaId,
    required int numeroMesa,
    required String mensaje,
  }) async {
    final clienteId = _service.currentUserId;
    if (clienteId == null) {
      throw const MesasFlowException('No hay un usuario autenticado.');
    }

    final texto = mensaje.trim();
    if (texto.isEmpty) {
      throw const MesasFlowException('Debes ingresar una consulta.');
    }

    await _service.crearConsultaMozo(
      mesaId: mesaId,
      clienteId: clienteId,
      numeroMesa: numeroMesa,
      mensaje: texto,
    );

    await _notificarPorPerfiles(
      perfiles: const ['mozo'],
      titulo: 'Consulta rápida de cliente',
      mensaje: 'Mesa $numeroMesa: $texto',
      tipo: 'consulta_mozo',
      referenciaId: mesaId,
      payload: {'mesaId': mesaId, 'numeroMesa': numeroMesa},
    );
  }

  Future<List<Map<String, dynamic>>> getConsultasRapidasDeMiMesa({
    required String mesaId,
  }) async {
    final clienteId = _service.currentUserId;
    if (clienteId == null) {
      throw const MesasFlowException('No hay un usuario autenticado.');
    }

    return _service.getConsultasByClienteMesa(
      mesaId: mesaId,
      clienteId: clienteId,
    );
  }

  // metre
  Future<void> asignarMesa({required Map cliente, required Map mesa}) async {
    final puede = await canCurrentUserManageTables();

    if (!puede) {
      throw Exception('No tenés permisos para asignar mesas.');
    }

    if (mesa['cliente_id'] != null) {
      throw Exception('La mesa ya está ocupada.');
    }

    final mesaExistente = await _service.buscarMesaPorCliente(cliente['id']);

    if (mesaExistente != null) {
      throw Exception('El cliente ya tiene una mesa asignada.');
    }

    await _service.asignarMesa(clienteId: cliente['id'], mesaId: mesa['id']);
    await _service.marcarSolicitudesAsignadas(
      clienteId: cliente['id'] as String,
      mesaId: mesa['id'] as String,
    );

    await _notificacionesService.enviarNotificaciones(
      destinatarios: [cliente['id'] as String],
      titulo: 'Mesa asignada',
      mensaje: 'Te asignaron la mesa ${mesa['numero']}.',
      tipo: 'mesa_asignada',
      referenciaId: mesa['id'] as String,
      payload: {'mesaId': mesa['id'], 'numeroMesa': mesa['numero']},
    );
  }

  Future<List<Map<String, dynamic>>> getClientesSinMesa() async {
    final clientesEnEspera = await _service.getClientesEnEspera();

    return clientesEnEspera
        .map(
          (solicitud) => <String, dynamic>{
            'id': solicitud['cliente_id'],
            'nombres': solicitud['nombres_snapshot'],
            'apellidos': solicitud['apellidos_snapshot'],
            'perfil': solicitud['perfil_snapshot'],
            'foto_url': solicitud['foto_url_snapshot'],
            'correo': null,
            'dni': null,
            'solicitud_id': solicitud['id'],
            'created_at': solicitud['created_at'],
          },
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>> getMesasDisponibles() async {
    final mesas = await _service.getMesas();

    return mesas.where((m) => m['cliente_id'] == null).toList();
  }

  Future<List<Map<String, dynamic>>> getMesasOcupadas() async {
    return await _service.getMesasOcupadas();
  }

  Future<List<Map<String, dynamic>>> getMensajesChatMesaCliente({
    required String mesaId,
  }) async {
    final clienteId = _service.currentUserId;
    if (clienteId == null) {
      throw const MesasFlowException('No hay un usuario autenticado.');
    }

    return _service.getMensajesChatMesa(mesaId: mesaId, clienteId: clienteId);
  }

  Future<List<Map<String, dynamic>>> getChatsActivosMozo() {
    return _service.getChatsActivosMozo();
  }

  Future<List<Map<String, dynamic>>> getMensajesChatMesaMozo({
    required String mesaId,
    required String clienteId,
  }) {
    return _service.getMensajesChatMesa(mesaId: mesaId, clienteId: clienteId);
  }

  Future<void> enviarMensajeChatCliente({
    required String mesaId,
    required int numeroMesa,
    required String mensaje,
  }) async {
    final clienteId = _service.currentUserId;
    if (clienteId == null) {
      throw const MesasFlowException('No hay un usuario autenticado.');
    }

    final texto = mensaje.trim();
    if (texto.length < 2) {
      throw const MesasFlowException('El mensaje es demasiado corto.');
    }

    await _service.enviarMensajeChat(
      mesaId: mesaId,
      numeroMesa: numeroMesa,
      clienteId: clienteId,
      remitentePerfil: 'cliente',
      mensaje: texto,
    );

    await _notificarPorPerfiles(
      perfiles: const ['mozo'],
      titulo: 'Mensaje de cliente',
      mensaje: 'Mesa $numeroMesa: $texto',
      tipo: 'chat_cliente_mozo',
      referenciaId: mesaId,
      payload: {'mesaId': mesaId, 'numeroMesa': numeroMesa},
    );
  }

  Future<void> enviarMensajeChatMozo({
    required String mesaId,
    required int numeroMesa,
    required String clienteId,
    required String mensaje,
  }) async {
    final texto = mensaje.trim();
    if (texto.length < 2) {
      throw const MesasFlowException('El mensaje es demasiado corto.');
    }

    await _service.enviarMensajeChat(
      mesaId: mesaId,
      numeroMesa: numeroMesa,
      clienteId: clienteId,
      remitentePerfil: 'mozo',
      mensaje: texto,
    );

    await _notificacionesService.enviarNotificaciones(
      destinatarios: [clienteId],
      titulo: 'Respuesta del mozo',
      mensaje: 'Mesa $numeroMesa: $texto',
      tipo: 'chat_mozo_cliente',
      referenciaId: mesaId,
      payload: {'mesaId': mesaId, 'numeroMesa': numeroMesa},
    );
  }

  Future<void> _notificarPorPerfiles({
    required List<String> perfiles,
    required String titulo,
    required String mensaje,
    required String tipo,
    String? referenciaId,
    Map<String, dynamic>? payload,
  }) async {
    // Helper central para no duplicar resolución de destinatarios por perfil.
    final destinatarios = await _notificacionesService.getUserIdsByPerfiles(
      perfiles,
    );
    await _notificacionesService.enviarNotificaciones(
      destinatarios: destinatarios,
      titulo: titulo,
      mensaje: mensaje,
      tipo: tipo,
      referenciaId: referenciaId,
      payload: payload,
    );
  }
}
