import 'package:all_food/src/features/chat/data/services/chat-service.dart';

class ChatRepository {
  ChatRepository({ChatService? service}) : _service = service ?? ChatService();

  final ChatService _service;

  String? get currentUserId => _service.currentUserId;

  Future<String> iniciarChat({
    required String mesaId,
    required String clienteId,
  }) {
    return _service.obtenerOCrearConsulta(mesaId: mesaId, clienteId: clienteId);
  }

  Future<void> cerrarConsultaPorMesa(String mesaId) {
    return _service.cerrarConsultaPorMesa(mesaId);
  }

  Future<void> enviarMensaje({
    required String consultaId,
    required String mensaje,
  }) {
    return _service.enviarMensaje(consultaId: consultaId, mensaje: mensaje);
  }

  Stream<List<Map<String, dynamic>>> mensajes(String consultaId) {
    return _service.escucharMensajes(consultaId);
  }
}
