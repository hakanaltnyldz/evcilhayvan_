// lib/core/socket_service.dart
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import 'http.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  IO.Socket? _socket;

  factory SocketService() => _instance;
  SocketService._internal();

  Future<void> connect() async {
    if (_socket != null && _socket!.connected) return;

    _socket?.dispose();

    final backendUri = Uri.parse(apiBaseUrl);
    final authority = backendUri.hasPort
        ? '${backendUri.scheme}://${backendUri.host}:${backendUri.port}'
        : '${backendUri.scheme}://${backendUri.host}';

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final builder = IO.OptionBuilder()
        .setTransports(['websocket'])
        .disableAutoConnect()
        // .setPath('/socket.io') // gerek yoksa ekleme
        ;

    if (token != null && token.isNotEmpty) {
      builder.setExtraHeaders({'Authorization': 'Bearer $token'});
    }

    final socket = IO.io(authority, builder.build());
    _socket = socket;

    // DEBUG logları çok yardımcı olur
    socket.onConnect((_) => print('✅ Socket bağlandı: ${socket.id}'));
    socket.onDisconnect((_) => print('❌ Socket bağlantısı koptu'));
    socket.onConnectError((e) => print('⚠️ connect_error: $e'));
    socket.onError((e) => print('⚠️ error: $e'));

    socket.connect();
  }

  // <<< DEĞİŞTİ >>>: joinConversation emit ediyoruz
  void joinRoom(String conversationId) {
    final socket = _socket;
    if (socket == null) return;
    if (socket.connected) {
      socket.emit('joinConversation', conversationId);
    } else {
      socket.onConnect((_) => socket.emit('joinConversation', conversationId));
    }
  }

  // <<< DEĞİŞTİ >>>: backend 'newMessage' emit ediyor; onu dinleyelim
  void onMessage(void Function(dynamic) callback) {
    final socket = _socket;
    if (socket == null) return;
    socket.off('newMessage'); // duplicate dinleyici olmasın
    socket.on('newMessage', callback);
  }

  // <<< DEĞİŞTİ >>>: backend 'sendMessage' payload: { conversationId, message }
  void sendMessage({
    required String conversationId,
    required Map<String, dynamic> message,
  }) {
    final socket = _socket;
    if (socket == null) return;
    socket.emit('sendMessage', {
      'conversationId': conversationId,
      'message': message,
    });
  }

  void disconnect() {
    final socket = _socket;
    if (socket == null) return;
    socket.disconnect();
    socket.dispose();
    _socket = null;
  }
}
