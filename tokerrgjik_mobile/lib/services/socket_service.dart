import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:tokerrgjik_mobile/config.dart';
import 'package:tokerrgjik_mobile/models/game_state.dart';

class SocketService {
  late io.Socket _socket;
  final GameState _gameState;
  Function(String message)? onPlayerJoined;
  Function(Map<String, dynamic> session)? onSessionUpdate;

  SocketService(this._gameState);

  void connect(String playerName, String gameMode, {String? sessionId}) {
    _socket = io.io(GameConfig.serverUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    _socket.connect();

    _socket.onConnect((_) {
      print('Connected to server');
      _socket.emit('setPlayerName', playerName);
      
      if (gameMode == 'online') {
        if (sessionId != null) {
          // Join specific session
          _socket.emit('joinSession', {'session_id': sessionId, 'username': playerName});
        } else {
          // Find any available game
          _socket.emit('findGame');
        }
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
    
    // New: Handle player joined notification
    _socket.on('playerJoined', (data) {
      print('Player joined: $data');
      if (onPlayerJoined != null) {
        final username = data['username'] ?? 'Unknown player';
        onPlayerJoined!('🎮 $username has joined the game!');
      }
    });
    
    // New: Handle session updates
    _socket.on('sessionUpdate', (data) {
      print('Session update: $data');
      if (onSessionUpdate != null) {
        onSessionUpdate!(data);
      }
    });

    _socket.onDisconnect((_) => print('Disconnected from server'));
  }
  
  void createSession(String hostUsername) {
    _socket.emit('createSession', {'host_username': hostUsername});
  }
  
  void joinSession(String sessionId, String username) {
    _socket.emit('joinSession', {'session_id': sessionId, 'username': username});
  }
  
  void leaveSession(String sessionId) {
    _socket.emit('leaveSession', {'session_id': sessionId});
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
