import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../providers/user_provider.dart';

final chatServiceProvider = Provider<ChatService>((ref) {
  final chatService = ChatService();
  final user = ref.watch(userProvider);
  if (user != null && user.id != null) {
    chatService.connect(user.id!);
  }
  ref.onDispose(() {
    chatService.disconnect();
  });
  return chatService;
});


class ChatService {
  WebSocketChannel? _channel;
  final StreamController<Map<String, dynamic>> _messageStreamController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Exponer el Stream para escuchar mensajes entrantes en tiempo real
  Stream<Map<String, dynamic>> get messageStream => _messageStreamController.stream;

  // URL base HTTP (detectando si corre en web o emulador móvil)
  final String _httpBaseUrl = kIsWeb
      ? 'http://localhost:8005'
      : 'http://10.0.2.2:8005';

  // Conectar al canal WebSocket del servidor
  Future<void> connect(String userId) async {
    if (_channel != null) {
      debugPrint('WebSocket ya está conectado o conectándose.');
      return;
    }
    final wsUrl = kIsWeb
        ? 'ws://localhost:8005/api/ws/chat/$userId'
        : 'ws://10.0.2.2:8005/api/ws/chat/$userId';

    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      debugPrint('Intentando conectar al WebSocket de chat...');

      _channel!.stream.listen(
        (data) {
          debugPrint('Mensaje WebSocket recibido: $data');
          try {
            final Map<String, dynamic> parsedMessage = json.decode(data);
            _messageStreamController.add(parsedMessage);
          } catch (e) {
            debugPrint('Error al decodificar mensaje JSON: $e');
          }
        },
        onError: (err) {
          debugPrint('Error en la conexión WebSocket: $err');
          _channel = null;
          _reconnect(userId);
        },
        onDone: () {
          debugPrint('Conexión WebSocket cerrada por el servidor');
          _channel = null;
        },
      );
    } catch (e) {
      debugPrint('Fallo al conectar WebSocket: $e');
      _channel = null;
      _reconnect(userId);
    }
  }

  // Intentar reconectar después de un breve delay
  void _reconnect(String userId) {
    Future.delayed(const Duration(seconds: 3), () {
      debugPrint('Reintentando conectar WebSocket...');
      connect(userId);
    });
  }

  // Enviar mensaje JSON al servidor
  void sendMessage(String receiverId, String text) {
    if (_channel != null) {
      final payload = json.encode({
        'receiver_id': receiverId,
        'message': text,
      });

      _channel!.sink.add(payload);
      debugPrint('Mensaje enviado por WebSocket: $payload');
    } else {
      debugPrint('No se pudo enviar el mensaje: WebSocket no está abierto');
    }
  }

  // Cargar historial de chat persistido en el servidor
  Future<List<Map<String, dynamic>>> getHistory(String userId, String otherUserId) async {
    try {
      final response = await http.get(
        Uri.parse('$_httpBaseUrl/api/chat/history/$userId/$otherUserId'),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        debugPrint('Error al obtener historial de chat: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error de red al consultar el historial de chat: $e');
      return [];
    }
  }

  // Desconectar de forma segura
  Future<void> disconnect() async {
    await _channel?.sink.close();
    _channel = null;
    debugPrint('Desconectado manualmente del WebSocket');
  }

  // Buscar usuarios por nombre o email
  Future<List<Map<String, dynamic>>> searchUsers(String query, String excludeUserId) async {
    try {
      final response = await http.get(
        Uri.parse('$_httpBaseUrl/api/users/search?query=${Uri.encodeComponent(query)}&exclude_user_id=$excludeUserId'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        debugPrint('Error al buscar usuarios: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error de red al buscar usuarios: $e');
      return [];
    }
  }

  // Agregar un contacto
  Future<Map<String, dynamic>> addContact(String userId, String emailOrName) async {
    try {
      final response = await http.post(
        Uri.parse('$_httpBaseUrl/api/contacts/add'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'email_or_name': emailOrName,
        }),
      );
      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message'] ?? 'Contacto agregado', 'contact': data['contact']};
      } else {
        return {'success': false, 'message': data['detail'] ?? 'Error al agregar contacto'};
      }
    } catch (e) {
      debugPrint('Error de red al agregar contacto: $e');
      return {'success': false, 'message': 'Error de red: $e'};
    }
  }

  // Obtener lista de contactos
  Future<List<Map<String, dynamic>>> getContacts(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_httpBaseUrl/api/contacts/$userId'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        debugPrint('Error al obtener contactos: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error de red al obtener contactos: $e');
      return [];
    }
  }

  // Obtener conversaciones activas
  Future<List<Map<String, dynamic>>> getConversations(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_httpBaseUrl/api/chat/conversations/$userId'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        debugPrint('Error al obtener conversaciones: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error de red al obtener conversaciones: $e');
      return [];
    }
  }
}
