import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';

class SocketService {
  static late IO.Socket socket;

  static Future<void> initSocket() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');

    socket = IO.io(socketUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.connect();
    
    socket.onConnect((_) {
      print('Connected to Socket');
      if (userId != null) socket.emit('join', userId);
    });
  }

  static void sendMessage(String receiverId, String text) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? senderId = prefs.getString('userId');
    if (senderId == null) return;

    socket.emit('send-message', {
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text
    });
  }
}