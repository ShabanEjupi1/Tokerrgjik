import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';
import '../config/api_keys.dart';

/// Enhanced Multiplayer Service
/// Supports:
/// - Public matchmaking
/// - Private room codes
/// - LAN play (local network)
/// - Friend invitations
/// - Spectator mode
class MultiplayerService {
  io.Socket? _socket;
  bool _isConnected = false;
  String? _currentRoomId;
  // ignore: unused_field
  String? _playerId;
  RoomType _currentRoomType = RoomType.none;
  
  // Callbacks
  Function(String message)? onError;
  Function(Map<String, dynamic> roomData)? onRoomJoined;
  Function(Map<String, dynamic> roomData)? onRoomUpdated;
  Function(String playerId)? onPlayerJoined;
  Function(String playerId)? onPlayerLeft;
  Function(Map<String, dynamic> gameData)? onGameStarted;
  Function(Map<String, dynamic> moveData)? onMoveMade;
  Function(Map<String, dynamic> result)? onGameEnded;
  Function(Map<String, dynamic> message)? onChatMessage;
  Function()? onDisconnected;
  Function()? onReconnected;

  // Network info
  final NetworkInfo _networkInfo = NetworkInfo();
  final Connectivity _connectivity = Connectivity();
  String? _localIP;

  /// Initialize the service
  Future<void> initialize() async {
    try {
      // Get local IP for LAN play
      _localIP = await _networkInfo.getWifiIP();
      print('MultiplayerService: Local IP: $_localIP');
    } catch (e) {
      print('MultiplayerService: Could not get local IP: $e');
    }
  }

  /// Connect to server
  Future<void> connect({
    required String playerId,
    required String playerName,
    String? serverUrl,
  }) async {
    if (_isConnected) {
      print('MultiplayerService: Already connected');
      return;
    }

    _playerId = playerId;
    final url = serverUrl ?? ApiKeys.currentServerUrl;

    try {
      _socket = io.io(
        url,
        io.OptionBuilder()
            .setTransports(['websocket'])
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionAttempts(5)
            .setReconnectionDelay(2000)
            .setReconnectionDelayMax(10000)
            .setExtraHeaders({
              'player_id': playerId,
              'player_name': playerName,
            })
            .build(),
      );

      _setupSocketListeners();
      _socket!.connect();

      print('MultiplayerService: Connecting to $url');
    } catch (e) {
      print('MultiplayerService connection error: $e');
      onError?.call('Failed to connect to server: $e');
    }
  }

  /// Setup socket event listeners
  void _setupSocketListeners() {
    _socket?.on('connect', (_) {
      print('MultiplayerService: Connected');
      _isConnected = true;
      onReconnected?.call();
    });

    _socket?.on('disconnect', (_) {
      print('MultiplayerService: Disconnected');
      _isConnected = false;
      _currentRoomId = null;
      onDisconnected?.call();
    });

    _socket?.on('error', (data) {
      print('MultiplayerService error: $data');
      onError?.call(data.toString());
    });

    _socket?.on('room_joined', (data) {
      print('MultiplayerService: Room joined: $data');
      _currentRoomId = data['room_id'];
      _currentRoomType = _parseRoomType(data['room_type']);
      onRoomJoined?.call(Map<String, dynamic>.from(data));
    });

    _socket?.on('room_updated', (data) {
      print('MultiplayerService: Room updated: $data');
      onRoomUpdated?.call(Map<String, dynamic>.from(data));
    });

    _socket?.on('player_joined', (data) {
      print('MultiplayerService: Player joined: $data');
      onPlayerJoined?.call(data['player_id']);
    });

    _socket?.on('player_left', (data) {
      print('MultiplayerService: Player left: $data');
      onPlayerLeft?.call(data['player_id']);
    });

    _socket?.on('game_started', (data) {
      print('MultiplayerService: Game started: $data');
      onGameStarted?.call(Map<String, dynamic>.from(data));
    });

    _socket?.on('move_made', (data) {
      print('MultiplayerService: Move made: $data');
      onMoveMade?.call(Map<String, dynamic>.from(data));
    });

    _socket?.on('game_ended', (data) {
      print('MultiplayerService: Game ended: $data');
      onGameEnded?.call(Map<String, dynamic>.from(data));
    });

    _socket?.on('chat_message', (data) {
      print('MultiplayerService: Chat message: $data');
      onChatMessage?.call(Map<String, dynamic>.from(data));
    });
  }

  // ==================== ROOM MANAGEMENT ====================

  /// Join public matchmaking queue
  Future<void> joinPublicQueue({
    String gameMode = 'standard',
    int? skillLevel,
  }) async {
    if (!_isConnected) {
      onError?.call('Not connected to server');
      return;
    }

    _socket?.emit('join_public_queue', {
      'game_mode': gameMode,
      'skill_level': skillLevel,
    });

    print('MultiplayerService: Joined public queue');
  }

  /// Create a private room
  Future<String?> createPrivateRoom({
    required String roomName,
    String? password,
    int maxPlayers = 2,
    String gameMode = 'standard',
    Map<String, dynamic>? customSettings,
  }) async {
    if (!_isConnected) {
      onError?.call('Not connected to server');
      return null;
    }

    final completer = Completer<String?>();

    _socket?.emitWithAck('create_private_room', {
      'room_name': roomName,
      'password': password,
      'max_players': maxPlayers,
      'game_mode': gameMode,
      'custom_settings': customSettings,
    }, ack: (data) {
      if (data['success']) {
        final roomCode = data['room_code'] as String;
        print('MultiplayerService: Created private room: $roomCode');
        completer.complete(roomCode);
      } else {
        onError?.call(data['error'] ?? 'Failed to create room');
        completer.complete(null);
      }
    });

    return completer.future;
  }

  /// Join private room with code
  Future<bool> joinPrivateRoom({
    required String roomCode,
    String? password,
  }) async {
    if (!_isConnected) {
      onError?.call('Not connected to server');
      return false;
    }

    final completer = Completer<bool>();

    _socket?.emitWithAck('join_private_room', {
      'room_code': roomCode,
      'password': password,
    }, ack: (data) {
      if (data['success']) {
        print('MultiplayerService: Joined private room: $roomCode');
        completer.complete(true);
      } else {
        onError?.call(data['error'] ?? 'Failed to join room');
        completer.complete(false);
      }
    });

    return completer.future;
  }

  /// Create LAN room (local network play)
  Future<String?> createLANRoom({
    required String roomName,
    int maxPlayers = 2,
  }) async {
    if (_localIP == null) {
      onError?.call('Local IP not available. Make sure you\'re connected to WiFi.');
      return null;
    }

    // For LAN, we use a local server or peer-to-peer
    // This is a simplified implementation
    return createPrivateRoom(
      roomName: roomName,
      maxPlayers: maxPlayers,
      customSettings: {
        'lan_mode': true,
        'host_ip': _localIP,
      },
    );
  }

  /// Get list of available LAN rooms
  Future<List<Map<String, dynamic>>> scanLANRooms() async {
    if (!_isConnected) {
      onError?.call('Not connected to server');
      return [];
    }

    final completer = Completer<List<Map<String, dynamic>>>();

    _socket?.emitWithAck('scan_lan_rooms', {
      'local_ip': _localIP,
    }, ack: (data) {
      if (data['success']) {
        final rooms = List<Map<String, dynamic>>.from(data['rooms'] ?? []);
        completer.complete(rooms);
      } else {
        completer.complete([]);
      }
    });

    return completer.future;
  }

  /// Invite friend to room
  Future<void> inviteFriend(String friendId) async {
    if (!_isConnected || _currentRoomId == null) {
      onError?.call('Not in a room');
      return;
    }

    _socket?.emit('invite_friend', {
      'friend_id': friendId,
      'room_id': _currentRoomId,
    });

    print('MultiplayerService: Invited friend: $friendId');
  }

  /// Leave current room
  Future<void> leaveRoom() async {
    if (!_isConnected) return;

    _socket?.emit('leave_room', {
      'room_id': _currentRoomId,
    });

    _currentRoomId = null;
    _currentRoomType = RoomType.none;
    print('MultiplayerService: Left room');
  }

  // ==================== GAME ACTIONS ====================

  /// Make a move in the game
  Future<void> makeMove(Map<String, dynamic> moveData) async {
    if (!_isConnected || _currentRoomId == null) {
      onError?.call('Not in an active game');
      return;
    }

    _socket?.emit('make_move', {
      'room_id': _currentRoomId,
      'move_data': moveData,
    });
  }

  /// Request game start (for private rooms)
  Future<void> startGame() async {
    if (!_isConnected || _currentRoomId == null) {
      onError?.call('Not in a room');
      return;
    }

    _socket?.emit('start_game', {
      'room_id': _currentRoomId,
    });
  }

  /// Forfeit the game
  Future<void> forfeit() async {
    if (!_isConnected || _currentRoomId == null) {
      onError?.call('Not in an active game');
      return;
    }

    _socket?.emit('forfeit_game', {
      'room_id': _currentRoomId,
    });
  }

  /// Request rematch
  Future<void> requestRematch() async {
    if (!_isConnected || _currentRoomId == null) {
      onError?.call('Not in a room');
      return;
    }

    _socket?.emit('request_rematch', {
      'room_id': _currentRoomId,
    });
  }

  // ==================== CHAT ====================

  /// Send chat message
  Future<void> sendMessage(String message) async {
    if (!_isConnected || _currentRoomId == null) {
      onError?.call('Not in a room');
      return;
    }

    _socket?.emit('chat_message', {
      'room_id': _currentRoomId,
      'message': message,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Send quick chat (predefined messages)
  Future<void> sendQuickChat(String messageId) async {
    sendMessage('QUICK_CHAT:$messageId');
  }

  // ==================== SPECTATOR MODE ====================

  /// Join as spectator
  Future<bool> joinAsSpectator(String roomCode) async {
    if (!_isConnected) {
      onError?.call('Not connected to server');
      return false;
    }

    final completer = Completer<bool>();

    _socket?.emitWithAck('join_as_spectator', {
      'room_code': roomCode,
    }, ack: (data) {
      completer.complete(data['success'] ?? false);
    });

    return completer.future;
  }

  // ==================== UTILITY ====================

  /// Check if connected
  bool get isConnected => _isConnected;

  /// Get current room ID
  String? get currentRoomId => _currentRoomId;

  /// Get current room type
  RoomType get currentRoomType => _currentRoomType;

  /// Get local IP for LAN play
  String? get localIP => _localIP;

  /// Check network connectivity
  Future<bool> checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  /// Parse room type from string
  RoomType _parseRoomType(String? type) {
    switch (type) {
      case 'public':
        return RoomType.public;
      case 'private':
        return RoomType.private;
      case 'lan':
        return RoomType.lan;
      case 'friend':
        return RoomType.friend;
      default:
        return RoomType.none;
    }
  }

  /// Disconnect from server
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
    _currentRoomId = null;
    _currentRoomType = RoomType.none;
    print('MultiplayerService: Disconnected');
  }

  /// Dispose service
  void dispose() {
    disconnect();
  }
}

/// Room types
enum RoomType {
  none,
  public,
  private,
  lan,
  friend,
}

/// Quick chat messages
class QuickChatMessages {
  static const Map<String, String> messages = {
    'gg': 'Good game!',
    'gl': 'Good luck!',
    'nice': 'Nice move!',
    'oops': 'Oops!',
    'thinking': 'Let me think...',
    'thanks': 'Thanks!',
    'wow': 'Wow!',
    'sorry': 'Sorry!',
  };
}
