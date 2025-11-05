import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:tokerrgjik_mobile/config.dart';
import 'package:tokerrgjik_mobile/models/game_state.dart';

class SocketService {
  late io.Socket _socket;
  final GameState _gameState;

  SocketService(this._gameState);

  void connect(String playerName, String gameMode) {
    _socket = io.io(GameConfig.serverUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    _socket.connect();

    _socket.onConnect((_) {
      print('Connected to server');
      _socket.emit('setPlayerName', playerName);
      if (gameMode == 'online') {
        _socket.emit('findGame');
      }
    });

    _socket.on('gameStart', (data) {
      _gameState.setGameState(data);
    });

    _socket.on('opponentMove', (data) {
      _gameState.setGameState(data);
    });
    
    _socket.on('gameEnded', (data) {
       _gameState.updateStatus(data['winnerName'] != null ? "Winner is ${data['winnerName']}" : "It's a draw!");
    });

    _socket.on('chatMessage', (data) {
      // Handle chat messages
    });

    _socket.onDisconnect((_) => print('Disconnected from server'));
  }

  void sendMove(Map<String, dynamic> move) {
    _socket.emit('gameMove', move);
  }
  
  void sendChatMessage(String message) {
    _socket.emit('chatMessage', message);
  }

  void dispose() {
    _socket.dispose();
  }
}
