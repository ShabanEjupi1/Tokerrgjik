import 'dart:async';
import 'api_service.dart';
import 'auth_service.dart';

class ChallengesService {
  static Timer? _pollTimer;
  static int _pendingChallengesCount = 0;
  static List<Map<String, dynamic>> _pendingChallenges = [];
  static final List<Function(int)> _listeners = [];

  /// Get count of pending challenges
  static int get pendingCount => _pendingChallengesCount;

  /// Get list of pending challenges
  static List<Map<String, dynamic>> get pendingChallenges => _pendingChallenges;

  /// Add a listener for challenge count changes
  static void addListener(Function(int) listener) {
    _listeners.add(listener);
  }

  /// Remove a listener
  static void removeListener(Function(int) listener) {
    _listeners.remove(listener);
  }

  /// Notify all listeners
  static void _notifyListeners() {
    for (var listener in _listeners) {
      listener(_pendingChallengesCount);
    }
  }

  /// Start polling for challenges
  static void startPolling() {
    stopPolling(); // Stop any existing timer
    
    // Poll immediately
    _checkChallenges();
    
    // Then poll every 15 seconds
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      _checkChallenges();
    });
  }

  /// Stop polling
  static void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  /// Check for new challenges
  static Future<void> _checkChallenges() async {
    try {
      final username = AuthService.currentUsername;
      if (username == null) return;

      final response = await ApiService.get(
        '/challenges',
        queryParams: {
          'username': username,
          'action': 'received',
        },
      );

      if (response['success'] == true) {
        _pendingChallenges = List<Map<String, dynamic>>.from(
          response['challenges'] ?? []
        );
        _pendingChallengesCount = _pendingChallenges.length;
        _notifyListeners();
      }
    } catch (e) {
      print('Error checking challenges: $e');
    }
  }

  /// Get pending challenges for current user
  static Future<List<Map<String, dynamic>>> getPendingChallenges() async {
    try {
      final username = AuthService.currentUsername;
      if (username == null) return [];

      final response = await ApiService.get(
        '/challenges',
        queryParams: {
          'username': username,
          'action': 'received',
        },
      );

      if (response['success'] == true) {
        return List<Map<String, dynamic>>.from(response['challenges'] ?? []);
      }
      return [];
    } catch (e) {
      print('Error fetching challenges: $e');
      return [];
    }
  }

  /// Send a challenge to another user
  static Future<bool> sendChallenge({
    required String fromUsername,
    required String toUsername,
    String? sessionId,
  }) async {
    try {
      final response = await ApiService.post('/challenges', {
        'action': 'send',
        'from_username': fromUsername,
        'to_username': toUsername,
        'session_id': sessionId,
      });

      return response['success'] == true;
    } catch (e) {
      print('Error sending challenge: $e');
      return false;
    }
  }

  /// Accept a challenge
  static Future<bool> acceptChallenge({
    required String challengeId,
    required String username,
  }) async {
    try {
      final response = await ApiService.post('/challenges', {
        'action': 'accept',
        'challenge_id': challengeId,
        'to_username': username,
      });

      if (response['success'] == true) {
        // Refresh challenges
        await _checkChallenges();
        return true;
      }
      return false;
    } catch (e) {
      print('Error accepting challenge: $e');
      return false;
    }
  }

  /// Decline a challenge
  static Future<bool> declineChallenge({
    required String challengeId,
    required String username,
  }) async {
    try {
      final response = await ApiService.post('/challenges', {
        'action': 'decline',
        'challenge_id': challengeId,
        'to_username': username,
      });

      if (response['success'] == true) {
        // Refresh challenges
        await _checkChallenges();
        return true;
      }
      return false;
    } catch (e) {
      print('Error declining challenge: $e');
      return false;
    }
  }

  /// Get sent challenges
  static Future<List<Map<String, dynamic>>> getSentChallenges() async {
    try {
      final username = AuthService.currentUsername;
      if (username == null) return [];

      final response = await ApiService.get(
        '/challenges',
        queryParams: {
          'username': username,
          'action': 'sent',
        },
      );

      if (response['success'] == true) {
        return List<Map<String, dynamic>>.from(response['challenges'] ?? []);
      }
      return [];
    } catch (e) {
      print('Error fetching sent challenges: $e');
      return [];
    }
  }

  /// Cancel a sent challenge
  static Future<bool> cancelChallenge({
    required String challengeId,
    required String username,
  }) async {
    try {
      final response = await ApiService.delete(
        '/challenges',
        queryParams: {
          'challenge_id': challengeId,
          'username': username,
        },
      );

      if (response['success'] == true) {
        return true;
      }
      return false;
    } catch (e) {
      print('Error canceling challenge: $e');
      return false;
    }
  }
}
