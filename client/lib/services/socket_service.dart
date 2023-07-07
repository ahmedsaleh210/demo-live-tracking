import 'dart:developer';

import 'package:socket_io_client/socket_io_client.dart' as socket_io;

import '../constants.dart';

class SocketService {
  static SocketService? _instance;
  late socket_io.Socket socket;

  factory SocketService() {
    _instance ??= SocketService._lazySingleton();
    return _instance!;
  }

  SocketService._lazySingleton() {
    try {
      socket = socket_io.io(SocketConstants.socketUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': true,
      });
      socket.onConnect((_) {
        log('connect');
      });
      socket.onDisconnect((_) => log('disconnect'));
      socket.connect();
    } catch (e) {
      log(e.toString());
    }
  }

  void disconnect() {
    socket.disconnect();
  }
}
