import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../config/api_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import '../services/api_service.dart';

/// Authentication service for user login/register
/// - Web: Uses backend API with JWT tokens
/// - Mobile: Uses local storage (offline mode)
class AuthService {
  static final String _baseUrl = ApiKeys.currentServerUrl;
  static String? _currentUserId;
  static String? _authToken;
  static String? _currentUsername;
  static bool _isGuest = false;
  
  // Albanian and gaming-style names for auto-generated usernames
  static const List<String> _firstNames = [
    'Enis', 'Linda', 'Arben', 'Besar', 'Luan',
    'Alban', 'Ilir', 'Dritan', 'Kujtim',
    'Ardit', 'Besnik', 'Durim', 'Fatmir',
    'Agron', 'Flamur', 'Korab', 'Enver',
  ];
  
  static const List<String> _suffixes = [
    'Gamer', 'Pro', 'Boss', 'Mbreti', 'Drejtori', 'Legend', 'Hero',
    'Master', 'Warrior', 'Champion', 'Winner', 'Player', 'Fighter', 'Ninja', 'Ace',
    'Shqipja', 'Shqiptar', 'Kosovar', 'Ilir', 'Eagle', 'Lion', 'Baba',
  ];
  
  /// Generate a fun random username (e.g., EnisGamer775, LindaShqipja123)
  static String generateRandomUsername() {
    final random = Random();
    final firstName = _firstNames[random.nextInt(_firstNames.length)];
    final suffix = _suffixes[random.nextInt(_suffixes.length)];
    final number = random.nextInt(999);
    return '$firstName$suffix$number';
  }
  
  /// Register new user
  /// ALWAYS saves to BOTH local storage AND Neon database for backup
  static Future<Map<String, dynamic>?> register({
    required String username,
    required String password,
    String? email,
  }) async {
    // ALWAYS try to save to Neon database first (for backup)
    try {
      final result = await ApiService.post('/auth', {
        'action': 'register',
        'username': username,
        'password': password,
        if (email != null) 'email': email,
      });

      if (result != null) {
        // Extract user data from response
        final userData = result['user'];
        if (userData != null) {
          _currentUserId = userData['id']?.toString() ?? 'user_${DateTime.now().millisecondsSinceEpoch}';
          _currentUsername = userData['username'] ?? username;
          _authToken = result['token'];
          _isGuest = false;
          await _saveAuthLocal();
          
          // Clear any guest session
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('guest_id');
          await prefs.remove('guest_username');
          
          print('✅ User registered in Neon database: $_currentUsername');
          return { 
            'success': true,
            'user': userData,
            'token': _authToken,
          };
        }
      }
    } catch (e) {
      print('⚠️ Neon registration failed: $e');
      return {
        'success': false,
        'error': 'Registration failed. Username may already exist.',
      };
    }
    
    return {
      'success': false,
      'error': 'Registration failed. Please try again.',
    };
  }
  
  /// Login user
  /// ALWAYS tries Neon database first, falls back to local storage
  static Future<Map<String, dynamic>?> login({
    required String username,
    required String password,
  }) async {
    // ALWAYS try server login first (for backup sync)
    try {
      final result = await ApiService.post('/auth', {
        'action': 'login',
        'username': username,
        'password': password,
      });

      if (result != null) {
        // Extract user data from response
        final userData = result['user'];
        if (userData != null) {
          _currentUserId = userData['id']?.toString() ?? 'user_${DateTime.now().millisecondsSinceEpoch}';
          _currentUsername = userData['username'] ?? username;
          _authToken = result['token'];
          _isGuest = false;
          await _saveAuthLocal();
          
          // Clear any guest session
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('guest_id');
          await prefs.remove('guest_username');
          
          print('✅ Logged in via Neon database: $_currentUsername');
          return { 
            'success': true,
            'user': userData,
            'token': _authToken,
          };
        }
      }
    } catch (e) {
      print('⚠️ Neon login failed: $e');
      return {
        'success': false,
        'error': 'Login failed. Please check your credentials.',
      };
    }
    
    return {
      'success': false,
      'error': 'Invalid username or password',
    };
  }
  
  /// Guest login (no account needed)
  static Future<Map<String, dynamic>> loginAsGuest() async {
    // Check if guest session already exists
    final prefs = await SharedPreferences.getInstance();
    String? existingGuestId = prefs.getString('guest_id');
    String? existingGuestName = prefs.getString('guest_username');
    
    if (existingGuestId != null && existingGuestName != null) {
      // Reuse existing guest session
      _currentUserId = existingGuestId;
      _currentUsername = existingGuestName;
      _isGuest = true;
      
      return {
        'userId': existingGuestId,
        'username': existingGuestName,
        'isGuest': true,
        'success': true,
      };
    }
    
    // Create new guest session
    final guestId = 'guest_${Random().nextInt(999999)}';
    final guestName = generateRandomUsername(); // Use fun random name instead of "Guest_XXXX"
    
    _currentUserId = guestId;
    _currentUsername = guestName;
    _isGuest = true;
    
    // Save guest session
    await prefs.setString('guest_id', guestId);
    await prefs.setString('guest_username', guestName);
    await _saveAuthLocal();
    
    return {
      'userId': guestId,
      'username': guestName,
      'isGuest': true,
      'success': true,
    };
  }
  
  /// Create local user (fallback)
  static Future<Map<String, dynamic>> _createLocalUser(String username) async {
    _currentUserId = 'local_${DateTime.now().millisecondsSinceEpoch}';
    _currentUsername = username;
    await _saveAuthLocal();
    return {
      'userId': _currentUserId,
      'username': username,
      'success': true,
      'offline': true,
    };
  }
  
  /// Logout
  static Future<void> logout() async {
    if (kIsWeb && _authToken != null) {
      try {
        await ApiService.post('/auth', {
          'action': 'logout',
        }, headers: { 'Authorization': 'Bearer $_authToken' });
      } catch (e) {
        print('Logout error: $e');
      }
    }
    
    _currentUserId = null;
    _authToken = null;
    _currentUsername = null;
    _isGuest = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.remove('authToken');
    await prefs.remove('username');
  }
  
  /// Get current user ID
  static String? get currentUserId => _currentUserId;
  
  /// Get current username
  static String? get currentUsername => _currentUsername;
  
  /// Set current username (for quick updates)
  static set currentUsername(String? username) {
    _currentUsername = username;
  }
  
  /// Set current username (for profile updates)
  static Future<void> updateUsername(String newUsername) async {
    _currentUsername = newUsername;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', newUsername);
  }
  
  /// Get auth token for API calls
  static String? get authToken => _authToken;
  
  /// Check if logged in
  static bool get isLoggedIn => _currentUserId != null;
  
  /// Check if guest
  static bool get isGuest => _isGuest;
  
  /// Load auth from local storage
  static Future<void> _loadAuthLocal() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getString('userId');
    _authToken = prefs.getString('authToken');
    _currentUsername = prefs.getString('username');
  }
  
  /// Save auth to local storage
  static Future<void> _saveAuthLocal() async {
    final prefs = await SharedPreferences.getInstance();
    if (_currentUserId != null) {
      await prefs.setString('userId', _currentUserId!);
    }
    if (_authToken != null) {
      await prefs.setString('authToken', _authToken!);
    }
    if (_currentUsername != null) {
      await prefs.setString('username', _currentUsername!);
    }
  }
  
  /// Initialize (load saved auth)
  static Future<void> initialize() async {
    await _loadAuthLocal();
    
    // Check if we have a guest session
    final prefs = await SharedPreferences.getInstance();
    String? guestId = prefs.getString('guest_id');
    if (guestId != null && _currentUserId == guestId) {
      _isGuest = true;
    }
    
    // DON'T auto-login as guest - let the login screen handle it
    // Only restore existing session
    print('🔑 Auth initialized - User: $_currentUsername, Guest: $_isGuest');
  }
  
  /// Verify token is still valid (for web)
  static Future<bool> verifyToken() async {
    if (!kIsWeb || _authToken == null) return true;
    
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/auth/verify'),
        headers: {
          'Authorization': 'Bearer $_authToken',
        },
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (e) {
      print('Token verification error: $e');
      return false;
    }
  }
}
