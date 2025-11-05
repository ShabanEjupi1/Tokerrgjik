import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class SocketServiceRealtime {
  static final SocketServiceRealtime _instance = SocketServiceRealtime._internal();
  factory SocketServiceRealtime() => _instance;
  SocketServiceRealtime._internal();

  io.Socket? _socket;
  String? _username;
  String? _currentSessionId;
  
  // Callbacks
  Function(Map<String, dynamic>)? onSessionCreated;
  Function(Map<String, dynamic>)? onGameStarted;
  Function(Map<String, dynamic>)? onMoveMade;
  Function(Map<String, dynamic>)? onChatMessage;
  Function(String)? onPlayerDisconnected;
  Function(Map<String, dynamic>)? onLobbyUpdate;
  Function(List<Map<String, dynamic>>)? onSessionsUpdated;
  Function(String)? onError;

  bool get isConnected => _socket?.connected ?? false;
  String? get currentSessionId => _currentSessionId;

  // Initialize and connect to Socket.IO server
  Future<void> connect(String username, {String? serverUrl}) async {
    _username = username;
    
    // Use production URL or local development
    final url = serverUrl ?? 'https://tokerrgjik-socketio.onrender.com'; // Update with your deployed server
    
    debugPrint('🔌 Connecting to Socket.IO server: $url');
    
    _socket = io.io(url, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    _socket!.connect();

    // Setup event listeners
    _socket!.onConnect((_) {
      debugPrint('✅ Socket.IO connected: ${_socket!.id}');
      joinLobby();
    });

    _socket!.onDisconnect((_) {
      debugPrint('❌ Socket.IO disconnected');
    });

    _socket!.on('session_created', (data) {
      debugPrint('📋 Session created: $data');
      if (onSessionCreated != null) onSessionCreated!(data);
    });

    _socket!.on('game_started', (data) {
      debugPrint('🎮 Game started: $data');
      _currentSessionId = data['sessionId'].toString();
      if (onGameStarted != null) onGameStarted!(data);
    });

    _socket!.on('move_made', (data) {
      debugPrint('🎯 Move made: $data');
      if (onMoveMade != null) onMoveMade!(data);
    });

    _socket!.on('chat_message', (data) {
      debugPrint('💬 Chat message: $data');
      if (onChatMessage != null) onChatMessage!(data);
    });

    _socket!.on('player_disconnected', (data) {
      debugPrint('👋 Player disconnected: $data');
      if (onPlayerDisconnected != null) onPlayerDisconnected!(data['username']);
    });

    _socket!.on('lobby_update', (data) {
      debugPrint('📊 Lobby update: $data');
      if (onLobbyUpdate != null) onLobbyUpdate!(data);
    });

    _socket!.on('sessions_updated', (data) {
      debugPrint('🔄 Sessions updated: $data');
      final sessions = (data['sessions'] as List<dynamic>)
          .map((s) => Map<String, dynamic>.from(s))
          .toList();
      if (onSessionsUpdated != null) onSessionsUpdated!(sessions);
    });

    _socket!.on('error', (data) {
      debugPrint('⚠️ Socket error: $data');
      if (onError != null) onError!(data['message'] ?? 'Unknown error');
    });
  }

  // Join the lobby
  void joinLobby() {
    if (_socket?.connected ?? false) {
      _socket!.emit('join_lobby', {'username': _username});
    }
  }

  // Create a new game session
  void createSession({bool isPrivate = false, String? invitedUsername}) {
    if (_socket?.connected ?? false) {
      _socket!.emit('create_session', {
        'username': _username,
        'isPrivate': isPrivate,
        'invitedUsername': invitedUsername,
      });
    }
  }

  // Join an existing session
  void joinSession(String sessionId) {
    if (_socket?.connected ?? false) {
      _socket!.emit('join_session', {
        'sessionId': sessionId,
        'username': _username,
      });
    }
  }

  // Make a move in the game
  void makeMove({
    required String sessionId,
    required int position,
    required String action, // 'place', 'move', 'remove'
  }) {
    if (_socket?.connected ?? false) {
      _socket!.emit('make_move', {
        'sessionId': sessionId,
        'position': position,
        'action': action,
      });
    }
  }

  // Send a chat message
  void sendMessage(String sessionId, String message) {
    if (_socket?.connected ?? false) {
      _socket!.emit('send_message', {
        'sessionId': sessionId,
        'message': message,
      });
    }
  }

  // Disconnect from the server
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _currentSessionId = null;
    debugPrint('🔌 Socket.IO disconnected and disposed');
  }

  // Clear all callbacks
  void clearCallbacks() {
    onSessionCreated = null;
    onGameStarted = null;
    onMoveMade = null;
    onChatMessage = null;
    onPlayerDisconnected = null;
    onLobbyUpdate = null;
    onSessionsUpdated = null;
    onError = null;
  }
}
