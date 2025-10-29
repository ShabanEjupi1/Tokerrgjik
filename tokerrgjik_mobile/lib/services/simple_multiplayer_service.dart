import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'api_service.dart';
import 'local_storage_service.dart';

/// Simplified Multiplayer Service using Polling (No Socket.IO needed!)
/// 
/// Perfect for turn-based games on Netlify.
/// Uses simple HTTP polling every 2 seconds to check for game updates.
/// Much simpler than WebSockets and works great for TokerrGjiks.
class SimpleMultiplayerService {
  static final SimpleMultiplayerService _instance = SimpleMultiplayerService._internal();
  factory SimpleMultiplayerService() => _instance;
  SimpleMultiplayerService._internal();

  static String get baseUrl => kIsWeb ? 'https://tokerrgjik.netlify.app/.netlify/functions' : ApiService.baseUrl;
  Timer? _pollTimer;
  String? _currentSessionId;

  // Callbacks
  Function(Map<String, dynamic>)? onGameUpdate;
  Function(String)? onOpponentMove;
  Function(String)? onError;

  /// Create a new multiplayer game session
  Future<String?> createSession({
    required String hostUsername,
    String? guestUsername,
    bool isPrivate = false,
  }) async {
    try {
      // Use ApiService.post which handles base URLs and web/mobile differences
      final result = await ApiService.post('/games', {
        'action': 'create_session',
        'host_username': hostUsername,
        'guest_username': guestUsername,
        'is_private': isPrivate,
      });

      if (result != null && result['session_id'] != null) {
        _currentSessionId = result['session_id'].toString();
        startPolling(_currentSessionId!);
        debugPrint('✅ Session created: $_currentSessionId');
        return _currentSessionId;
      }
      // If no result (offline/mobile fallback), persist locally
      final local = LocalStorageService();
      await local.init();
      final sessions = local.getSetting('cached_sessions') ?? [];
      // create temporary session id
      final tempId = 'local_${DateTime.now().millisecondsSinceEpoch}';
      final newSession = {
        'session_id': tempId,
        'host_username': hostUsername,
        'status': 'waiting',
      };
      final updated = List<Map<String, dynamic>>.from(sessions)..add(newSession);
      await local.saveSetting('cached_sessions', updated);
      _currentSessionId = tempId;
      startPolling(_currentSessionId!);
      return _currentSessionId;
    } catch (e) {
      debugPrint('Error creating session: $e');
      if (onError != null) onError!('Failed to create game session');
      return null;
    }
  }

  /// Join an existing game session
  Future<bool> joinSession({
    required String sessionId,
    required String username,
  }) async {
    try {
      final result = await ApiService.post('/games', {
        'action': 'join_session',
        'session_id': sessionId,
        'username': username,
      });

      if (result != null) {
        _currentSessionId = sessionId;
        startPolling(sessionId);
        debugPrint('✅ Joined session: $sessionId');
        return true;
      }
      // Fallback: if local session exists, mark joined
      final local = LocalStorageService();
      await local.init();
      final sessions = local.getSetting('cached_sessions') ?? [];
      // Mark as active
      for (var s in sessions) {
        if (s['session_id'] == sessionId) {
          s['guest_username'] = username;
          s['status'] = 'active';
        }
      }
      await local.saveSetting('cached_sessions', sessions);
      _currentSessionId = sessionId;
      startPolling(sessionId);
      return true;
    } catch (e) {
      debugPrint('Error joining session: $e');
      if (onError != null) onError!('Failed to join game session');
      return false;
    }
  }

  /// Make a move in the current game
  Future<bool> makeMove({
    required String sessionId,
    required int position,
    required String action, // 'place', 'move', 'remove'
  }) async {
    try {
      final result = await ApiService.post('/games', {
        'action': 'make_move',
        'session_id': sessionId,
        'position': position,
        'move_action': action,
        'timestamp': DateTime.now().toIso8601String(),
      });

      if (result != null) {
        debugPrint('✅ Move made: position $position, action $action');
        return true;
      }
      // Fallback: store move locally
      final local = LocalStorageService();
      await local.init();
      final pending = local.getSetting('pending_moves') ?? [];
      final updated = List<Map<String, dynamic>>.from(pending)
        ..add({
          'session_id': sessionId,
          'position': position,
          'action': action,
          'timestamp': DateTime.now().toIso8601String(),
        });
      await local.saveSetting('pending_moves', updated);
      return true;
    } catch (e) {
      debugPrint('Error making move: $e');
      if (onError != null) onError!('Failed to make move');
      return false;
    }
  }

  /// Start polling for game updates (every 2 seconds)
  void startPolling(String sessionId) {
    stopPolling(); // Stop any existing polling
    
    debugPrint('🔄 Started polling session: $sessionId');
    
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      try {
        final response = await http.get(
          Uri.parse('$baseUrl/games?session_id=$sessionId&action=get_state'),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          
          // Notify listeners of game update
          if (onGameUpdate != null) {
            onGameUpdate!(data);
          }
          
          // Check if game is finished
          if (data['status'] == 'completed' || data['status'] == 'cancelled') {
            stopPolling();
            debugPrint('🏁 Game finished, stopped polling');
          }
        }
      } catch (e) {
        debugPrint('Polling error: $e');
        // Don't stop polling on errors, just continue
      }
    });
  }

  /// Stop polling for updates
  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    debugPrint('⏸️ Stopped polling');
  }

  /// Get list of available game sessions
  Future<List<Map<String, dynamic>>> getAvailableSessions() async {
    try {
      final result = await ApiService.get('/games?action=list_sessions');
      if (result != null && result['sessions'] != null) {
        return List<Map<String, dynamic>>.from(result['sessions']);
      }
      // Fallback to cached sessions
      final local = LocalStorageService();
      await local.init();
      return List<Map<String, dynamic>>.from(local.getSetting('cached_sessions') ?? []);
    } catch (e) {
      debugPrint('Error getting sessions: $e');
      return [];
    }
  }

  /// Leave current game session
  Future<void> leaveSession() async {
    if (_currentSessionId != null) {
      try {
        await ApiService.post('/games', {
          'action': 'leave_session',
          'session_id': _currentSessionId,
        });
      } catch (e) {
        debugPrint('Error leaving session: $e');
      }
      
      stopPolling();
      _currentSessionId = null;
    }
  }

  /// Clean up
  void dispose() {
    stopPolling();
    onGameUpdate = null;
    onOpponentMove = null;
    onError = null;
  }
}
