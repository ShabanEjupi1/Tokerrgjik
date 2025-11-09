import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../config/api_keys.dart';

/// API Service to communicate with Neon PostgreSQL backend
/// Handles all HTTP requests to the server
class ApiService {
  static const Duration _timeout = Duration(seconds: 10);
  
  // Dio instance for better web CORS support
  static final Dio _dio = Dio(BaseOptions(
    connectTimeout: _timeout,
    receiveTimeout: _timeout,
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
    // Enable cookies for CORS
    extra: {
      'withCredentials': false,
    },
  ));
  
  /// Base URL for API requests
  static String get baseUrl {
    // For web, use netlify functions or your backend URL
    if (kIsWeb) {
      return 'https://tokerrgjik.netlify.app/.netlify/functions';
    }
    return ApiKeys.currentServerUrl;
  }
  
  /// Make GET request
  static Future<Map<String, dynamic>?> get(String endpoint, {Map<String, String>? headers}) async {
    try {
      final url = '$baseUrl$endpoint';
      print('API GET: $url');
      
      // Use Dio for web to handle CORS better
      if (kIsWeb) {
        final response = await _dio.get(
          url,
          options: Options(
            headers: headers,
            validateStatus: (status) => status != null && status < 500,
          ),
        );
        
        if (response.statusCode == 200) {
          return response.data is String 
              ? json.decode(response.data) 
              : response.data;
        } else if (response.statusCode == 404) {
          print('⚠️ API endpoint not found (404): $endpoint');
          print('   This is expected if Netlify functions are not deployed yet.');
          print('   Using local storage fallback.');
          return null;
        } else {
          final errorBody = response.data.toString();
          final truncatedError = errorBody.length > 200 
              ? '${errorBody.substring(0, 200)}...' 
              : errorBody;
          print('API GET Error: ${response.statusCode} - $truncatedError');
          return null;
        }
      } else {
        // Use http package for mobile
        final response = await http.get(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            ...?headers,
          },
        ).timeout(_timeout);
        
        if (response.statusCode == 200) {
          return json.decode(response.body);
        } else if (response.statusCode == 404) {
          print('⚠️ API endpoint not found (404): $endpoint');
          print('   This is expected if Netlify functions are not deployed yet.');
          print('   Using local storage fallback.');
          return null;
        } else {
          final errorBody = response.body.length > 200 
              ? '${response.body.substring(0, 200)}...' 
              : response.body;
          print('API GET Error: ${response.statusCode} - $errorBody');
          return null;
        }
      }
    } on DioException catch (e) {
      print('API GET Dio Exception: ${e.type} - ${e.message}');
      if (e.response != null) {
        print('   Response: ${e.response?.statusCode} - ${e.response?.data}');
      }
      return null;
    } catch (e) {
      print('API GET Exception: $e');
      return null;
    }
  }
  
  /// Make POST request
  static Future<Map<String, dynamic>?> post(
    String endpoint,
    Map<String, dynamic> data, {
    Map<String, String>? headers,
  }) async {
    try {
      final url = '$baseUrl$endpoint';
      print('API POST: $url');
      
      // Use Dio for web to handle CORS better
      if (kIsWeb) {
        final response = await _dio.post(
          url,
          data: data,
          options: Options(
            headers: headers,
            validateStatus: (status) => status != null && status < 500,
          ),
        );
        
        if (response.statusCode == 200 || response.statusCode == 201) {
          return response.data is String 
              ? json.decode(response.data) 
              : response.data;
        } else if (response.statusCode == 404) {
          print('⚠️ API endpoint not found (404): $endpoint');
          print('   Using local storage fallback.');
          return null;
        } else {
          final errorBody = response.data.toString();
          final truncatedError = errorBody.length > 200 
              ? '${errorBody.substring(0, 200)}...' 
              : errorBody;
          print('API POST Error: ${response.statusCode} - $truncatedError');
          return null;
        }
      } else {
        // Use http package for mobile
        final response = await http.post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            ...?headers,
          },
          body: json.encode(data),
        ).timeout(_timeout);
        
        if (response.statusCode == 200 || response.statusCode == 201) {
          return json.decode(response.body);
        } else if (response.statusCode == 404) {
          print('⚠️ API endpoint not found (404): $endpoint');
          print('   Using local storage fallback.');
          return null;
        } else {
          final errorBody = response.body.length > 200 
              ? '${response.body.substring(0, 200)}...' 
              : response.body;
          print('API POST Error: ${response.statusCode} - $errorBody');
          return null;
        }
      }
    } on DioException catch (e) {
      print('API POST Dio Exception: ${e.type} - ${e.message}');
      if (e.response != null) {
        print('   Response: ${e.response?.statusCode} - ${e.response?.data}');
      }
      return null;
    } catch (e) {
      print('API POST Exception: $e');
      return null;
    }
  }
  
  /// Make PUT request
  static Future<Map<String, dynamic>?> put(
    String endpoint,
    Map<String, dynamic> data, {
    Map<String, String>? headers,
  }) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      print('API PUT: $url');
      
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          ...?headers,
        },
        body: json.encode(data),
      ).timeout(_timeout);
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('API PUT Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('API PUT Exception: $e');
      return null;
    }
  }
  
  /// Make DELETE request
  static Future<bool> delete(String endpoint, {Map<String, String>? headers}) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      print('API DELETE: $url');
      
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          ...?headers,
        },
      ).timeout(_timeout);
      
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('API DELETE Exception: $e');
      return false;
    }
  }
  
  // ==================== USER ENDPOINTS ====================
  
  /// Register new user
  static Future<Map<String, dynamic>?> registerUser({
    required String username,
    required String email,
    String? password,
  }) async {
    return await post('/users', {
      'username': username,
      'email': email,
      if (password != null) 'password': password,
    });
  }
  
  /// Get user by username
  static Future<Map<String, dynamic>?> getUserByUsername(String username) async {
    return await get('/users/$username');
  }
  
  /// Update user stats
  static Future<Map<String, dynamic>?> updateUserStats({
    required String username,
    int? wins,
    int? losses,
    int? draws,
    int? coins,
    int? level,
    int? xp,
  }) async {
    return await put('/users/$username/stats', {
      if (wins != null) 'wins': wins,
      if (losses != null) 'losses': losses,
      if (draws != null) 'draws': draws,
      if (coins != null) 'coins': coins,
      if (level != null) 'level': level,
      if (xp != null) 'xp': xp,
    });
  }
  
  /// Search users by username (for adding friends)
  static Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    final result = await get('/users/search?q=$query');
    if (result != null && result['users'] != null) {
      return List<Map<String, dynamic>>.from(result['users']);
    }
    return [];
  }
  
  /// Update user profile (username, email, full name)
  static Future<Map<String, dynamic>?> updateUserProfile({
    required String oldUsername,
    String? newUsername,
    String? email,
    String? fullName,
  }) async {
    return await put('/users/profile', {
      'old_username': oldUsername,
      if (newUsername != null && newUsername.isNotEmpty) 'new_username': newUsername,
      if (email != null) 'email': email,
      if (fullName != null) 'full_name': fullName,
    });
  }
  
  // ==================== LEADERBOARD ENDPOINTS ====================
  
  /// Get global leaderboard
  static Future<List<Map<String, dynamic>>> getLeaderboard({
    int limit = 100,
    int offset = 0,
  }) async {
    final result = await get('/leaderboard?limit=$limit&offset=$offset');
    if (result != null && result['leaderboard'] != null) {
      return List<Map<String, dynamic>>.from(result['leaderboard']);
    }
    return [];
  }
  
  /// Get user rank on leaderboard
  static Future<int?> getUserRank(String username) async {
    final result = await get('/leaderboard/rank/$username');
    return result?['rank'];
  }
  
  // ==================== GAME ENDPOINTS ====================
  
  /// Save game result
  static Future<Map<String, dynamic>?> saveGameResult({
    required String username,
    required String gameMode,
    required String result,
    String? opponentUsername,
    int? score,
    int? duration,
    int? movesCount,
  }) async {
    return await post('/games', {
      'username': username,
      'game_mode': gameMode,
      'result': result,
      if (opponentUsername != null) 'opponent_username': opponentUsername,
      if (score != null) 'score': score,
      if (duration != null) 'duration': duration,
      if (movesCount != null) 'moves_count': movesCount,
      'played_at': DateTime.now().toIso8601String(),
    });
  }
  
  /// Get game history for user
  static Future<List<Map<String, dynamic>>> getGameHistory(
    String username, {
    int limit = 50,
    int offset = 0,
  }) async {
    final result = await get('/games/$username?limit=$limit&offset=$offset');
    if (result != null && result['games'] != null) {
      return List<Map<String, dynamic>>.from(result['games']);
    }
    return [];
  }
  
  /// Get user statistics
  static Future<Map<String, dynamic>?> getUserStatistics(String username) async {
    return await get('/statistics/$username');
  }
  
  // ==================== FRIENDS ENDPOINTS ====================
  
  /// Send friend request
  static Future<bool> sendFriendRequest(String fromUsername, String toUsername) async {
    final result = await post('/friends', {
      'action': 'send_request',
      'user_username': fromUsername,
      'friend_username': toUsername,
    });
    return result != null && result['success'] == true;
  }
  
  /// Accept friend request
  static Future<bool> acceptFriendRequest(String username, String friendUsername) async {
    final result = await post('/friends', {
      'action': 'accept',
      'user_username': username,
      'friend_username': friendUsername,
    });
    return result != null;
  }
  
  /// Reject friend request
  static Future<bool> rejectFriendRequest(String username, String friendUsername) async {
    final result = await post('/friends', {
      'action': 'reject',
      'user_username': username,
      'friend_username': friendUsername,
    });
    return result != null;
  }
  
  /// Get user's friends list
  static Future<List<Map<String, dynamic>>> getFriends(String username) async {
    final result = await get('/friends?username=$username&action=list');
    if (result != null && result['friends'] != null) {
      return List<Map<String, dynamic>>.from(result['friends']);
    }
    return [];
  }
  
  /// Get pending friend requests
  static Future<List<Map<String, dynamic>>> getFriendRequests(String username) async {
    final result = await get('/friends?username=$username&action=requests');
    if (result != null && result['requests'] != null) {
      return List<Map<String, dynamic>>.from(result['requests']);
    }
    return [];
  }
  
  // ==================== MULTIPLAYER ENDPOINTS ====================
  
  /// Create multiplayer game session
  static Future<Map<String, dynamic>?> createGameSession({
    required String hostUsername,
    String? invitedUsername,
  }) async {
    return await post('/games', {
      'action': 'create_session',
      'host_username': hostUsername,
      if (invitedUsername != null) 'guest_username': invitedUsername,
    });
  }
  
  /// Join game session
  static Future<Map<String, dynamic>?> joinGameSession(
    String sessionId,
    String username,
  ) async {
    return await post('/games', {
      'action': 'join_session',
      'session_id': sessionId,
      'username': username,
    });
  }
  
  /// Get active game sessions
  static Future<List<Map<String, dynamic>>> getActiveSessions() async {
    final result = await post('/games', {
      'action': 'list_sessions',
    });
    if (result != null && result['sessions'] != null) {
      return List<Map<String, dynamic>>.from(result['sessions']);
    }
    return [];
  }
  
  // ==================== HEALTH CHECK ====================
  
  /// Check if API is available
  static Future<bool> checkHealth() async {
    try {
      final result = await get('/health');
      return result != null && result['status'] == 'ok';
    } catch (e) {
      return false;
    }
  }
}
