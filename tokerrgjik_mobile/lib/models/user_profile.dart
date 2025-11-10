import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class UserProfile extends ChangeNotifier {
  // Default constructor
  UserProfile();
  
  String _username = 'Player';
  int _coins = 100; // Starting coins
  int _totalWins = 0;
  int _totalLosses = 0;
  int _totalDraws = 0;
  int _winStreak = 0;
  int _bestStreak = 0;
  bool _isPro = false;
  DateTime? _lastLoginDate;
  int _consecutiveLogins = 0;
  
  // Customization
  String _boardTheme = 'classic'; // classic, modern, dark, custom
  Color _player1Color = const Color(0xFFFFF8DC); // Cream - visible on all themes
  Color _player2Color = Colors.black87;
  Color _boardColor = const Color(0xFFDAA520); // Gold board (classic theme)
  
  // Theme shop
  List<String> _unlockedThemes = ['default']; // Always have default unlocked
  String _currentTheme = 'default';
  
  // Ad-skip (temporary)
  DateTime? _adFreeUntil;
  
  // Settings
  bool _soundEnabled = true;
  bool _musicEnabled = true;
  bool _vibrateEnabled = true;
  String _difficulty = 'medium'; // easy, medium, hard, expert
  
  // Friends
  List<String> _friends = [];
  List<String> _friendRequests = [];
  
  // Getters
  String get username => _username;
  int get coins => _coins;
  int get totalWins => _totalWins;
  int get totalLosses => _totalLosses;
  int get totalDraws => _totalDraws;
  int get winStreak => _winStreak;
  int get bestStreak => _bestStreak;
  bool get isPro => _isPro;
  DateTime? get lastLoginDate => _lastLoginDate;
  int get consecutiveLogins => _consecutiveLogins;
  
  String get boardTheme => _boardTheme;
  Color get player1Color => _player1Color;
  Color get player2Color => _player2Color;
  Color get boardColor => _boardColor;
  
  List<String> get unlockedThemes => _unlockedThemes;
  String get currentTheme => _currentTheme;
  DateTime? get adFreeUntil => _adFreeUntil;
  bool get isAdFree => _isPro || (_adFreeUntil != null && DateTime.now().isBefore(_adFreeUntil!));
  
  bool get soundEnabled => _soundEnabled;
  bool get musicEnabled => _musicEnabled;
  bool get vibrateEnabled => _vibrateEnabled;
  String get difficulty => _difficulty;
  
  List<String> get friends => _friends;
  List<String> get friendRequests => _friendRequests;
  
  int get totalGames => _totalWins + _totalLosses + _totalDraws;
  double get winRate => totalGames > 0 ? (_totalWins / totalGames * 100) : 0;
  
  // Load from storage
  Future<void> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    _username = prefs.getString('username') ?? 'Player';
    _coins = prefs.getInt('coins') ?? 100;
    _totalWins = prefs.getInt('totalWins') ?? 0;
    _totalLosses = prefs.getInt('totalLosses') ?? 0;
    _totalDraws = prefs.getInt('totalDraws') ?? 0;
    _winStreak = prefs.getInt('winStreak') ?? 0;
    _bestStreak = prefs.getInt('bestStreak') ?? 0;
    _isPro = prefs.getBool('isPro') ?? false;
    
    final lastLogin = prefs.getString('lastLoginDate');
    if (lastLogin != null) {
      _lastLoginDate = DateTime.parse(lastLogin);
    }
    _consecutiveLogins = prefs.getInt('consecutiveLogins') ?? 0;
    
    _boardTheme = prefs.getString('boardTheme') ?? 'classic';
    _player1Color = Color(prefs.getInt('player1Color') ?? const Color(0xFFFFF8DC).value);
    _player2Color = Color(prefs.getInt('player2Color') ?? Colors.black87.value);
    _boardColor = Color(prefs.getInt('boardColor') ?? const Color(0xFFDAA520).value);
    
    final themesJson = prefs.getString('unlockedThemes');
    if (themesJson != null) {
      _unlockedThemes = List<String>.from(json.decode(themesJson));
    }
    _currentTheme = prefs.getString('currentTheme') ?? 'default';
    
    final adFreeString = prefs.getString('adFreeUntil');
    if (adFreeString != null) {
      _adFreeUntil = DateTime.parse(adFreeString);
    }
    
    _soundEnabled = prefs.getBool('soundEnabled') ?? true;
    _musicEnabled = prefs.getBool('musicEnabled') ?? true;
    _vibrateEnabled = prefs.getBool('vibrateEnabled') ?? true;
    _difficulty = prefs.getString('difficulty') ?? 'medium';
    
    final friendsJson = prefs.getString('friends');
    if (friendsJson != null) {
      _friends = List<String>.from(json.decode(friendsJson));
    }
    
    final requestsJson = prefs.getString('friendRequests');
    if (requestsJson != null) {
      _friendRequests = List<String>.from(json.decode(requestsJson));
    }
    
    // Check daily login reward
    await checkDailyLogin();
    
    notifyListeners();
  }
  
  // Save to storage - DUAL SAVE: Local + Neon backup
  Future<void> saveProfile() async {
    // 1. ALWAYS save to local storage (phone cache)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', _username);
    await prefs.setInt('coins', _coins);
    await prefs.setInt('totalWins', _totalWins);
    await prefs.setInt('totalLosses', _totalLosses);
    await prefs.setInt('totalDraws', _totalDraws);
    await prefs.setInt('winStreak', _winStreak);
    await prefs.setInt('bestStreak', _bestStreak);
    await prefs.setBool('isPro', _isPro);
    
    if (_lastLoginDate != null) {
      await prefs.setString('lastLoginDate', _lastLoginDate!.toIso8601String());
    }
    await prefs.setInt('consecutiveLogins', _consecutiveLogins);
    
    await prefs.setString('boardTheme', _boardTheme);
    await prefs.setInt('player1Color', _player1Color.value);
    await prefs.setInt('player2Color', _player2Color.value);
    await prefs.setInt('boardColor', _boardColor.value);
    
    await prefs.setString('unlockedThemes', json.encode(_unlockedThemes));
    await prefs.setString('currentTheme', _currentTheme);
    if (_adFreeUntil != null) {
      await prefs.setString('adFreeUntil', _adFreeUntil!.toIso8601String());
    }
    
    await prefs.setBool('soundEnabled', _soundEnabled);
    await prefs.setBool('musicEnabled', _musicEnabled);
    await prefs.setBool('vibrateEnabled', _vibrateEnabled);
    await prefs.setString('difficulty', _difficulty);
    
    await prefs.setString('friends', json.encode(_friends));
    await prefs.setString('friendRequests', json.encode(_friendRequests));
    
    // 2. ALSO save to Neon database (backup) - fire and forget
    _syncToDatabase();
  }
  
  // Background sync to Neon database (non-blocking)
  void _syncToDatabase() async {
    try {
      final userId = AuthService.currentUserId;
      if (userId == null) return;
      
      await ApiService.post('/users', {
        'action': 'update_stats',
        'userId': userId,
        'username': _username,
        'coins': _coins,
        'wins': _totalWins,
        'losses': _totalLosses,
        'draws': _totalDraws,
        'winStreak': _winStreak,
        'bestStreak': _bestStreak,
        'isPro': _isPro,
      });
      print('✅ Profile synced to Neon database');
    } catch (e) {
      print('⚠️ Database sync failed (offline?): $e');
      // Don't block - local save already succeeded
    }
  }
  
  // Check daily login
  Future<void> checkDailyLogin() async {
    final now = DateTime.now();
    if (_lastLoginDate == null || 
        !_isSameDay(_lastLoginDate!, now)) {
      
      // Check if consecutive
      if (_lastLoginDate != null && 
          _isConsecutiveDay(_lastLoginDate!, now)) {
        _consecutiveLogins++;
      } else if (_lastLoginDate == null || 
                 !_isConsecutiveDay(_lastLoginDate!, now)) {
        _consecutiveLogins = 1;
      }
      
      _lastLoginDate = now;
      
      // Award daily login bonus
      int bonus = 2; // Base 2 coins
      if (_consecutiveLogins >= 7) bonus = 10;
      else if (_consecutiveLogins >= 3) bonus = 5;
      
      addCoins(bonus);
      await saveProfile();
      
      return; // Return bonus amount for display
    }
  }
  
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
  
  bool _isConsecutiveDay(DateTime last, DateTime now) {
    final difference = now.difference(last).inDays;
    return difference == 1;
  }
  
  // Game results
  void recordWin() {
    _totalWins++;
    _winStreak++;
    if (_winStreak > _bestStreak) {
      _bestStreak = _winStreak;
    }
    
    // Award coins based on difficulty
    int reward = 5;
    switch (_difficulty) {
      case 'easy':
        reward = 3;
        break;
      case 'medium':
        reward = 5;
        break;
      case 'hard':
        reward = 8;
        break;
      case 'expert':
        reward = 12;
        break;
    }
    
    // Bonus for win streak
    if (_winStreak >= 3) reward += 2;
    if (_winStreak >= 5) reward += 5;
    
    addCoins(reward);
    saveProfile();
    notifyListeners();
  }
  
  void recordLoss() {
    _totalLosses++;
    _winStreak = 0;
    addCoins(1); // Consolation coin
    saveProfile();
    notifyListeners();
  }
  
  void recordDraw() {
    _totalDraws++;
    _winStreak = 0;
    addCoins(2);
    saveProfile();
    notifyListeners();
  }
  
  // Coins
  void addCoins(int amount) {
    _coins += amount;
    notifyListeners();
  }
  
  bool spendCoins(int amount) {
    if (_coins >= amount) {
      _coins -= amount;
      saveProfile();
      notifyListeners();
      return true;
    }
    return false;
  }
  
  // Pro upgrade
  void upgradeToPro() {
    _isPro = true;
    saveProfile();
    notifyListeners();
  }
  
  // Settings
  void updateSettings({
    bool? sound,
    bool? music,
    bool? vibrate,
    String? difficulty,
  }) {
    if (sound != null) _soundEnabled = sound;
    if (music != null) _musicEnabled = music;
    if (vibrate != null) _vibrateEnabled = vibrate;
    if (difficulty != null) _difficulty = difficulty;
    saveProfile();
    notifyListeners();
  }
  
  // Update username
  void updateUsername(String newUsername) {
    _username = newUsername;
    saveProfile();
    notifyListeners();
  }
  
  // Sync username from AuthService (called after login/register)
  Future<void> syncUsernameFromAuth() async {
    final authUsername = AuthService.currentUsername;
    if (authUsername != null && authUsername != _username) {
      _username = authUsername;
      await saveProfile();
      notifyListeners();
      print('✅ Username synced from AuthService: $_username');
    }
  }
  
  // Customization
  void updateTheme({
    String? theme,
    Color? player1,
    Color? player2,
    Color? board,
  }) {
    // Set theme first if provided
    if (theme != null) {
      _boardTheme = theme;
    }
    
    // Apply colors if provided
    if (player1 != null) _player1Color = player1;
    if (player2 != null) _player2Color = player2;
    if (board != null) _boardColor = board;
    
    // Only switch to 'custom' if colors are changed WITHOUT a theme name
    // This allows selecting predefined themes while still enabling custom color changes
    if (theme == null && (player1 != null || player2 != null || board != null)) {
      _boardTheme = 'custom';
    }
    
    saveProfile();
    notifyListeners();
  }
  
  // Friends
  void addFriend(String username) {
    if (!_friends.contains(username)) {
      _friends.add(username);
      saveProfile();
      notifyListeners();
    }
  }
  
  void removeFriend(String username) {
    _friends.remove(username);
    saveProfile();
    notifyListeners();
  }
  
  void sendFriendRequest(String username) {
    // This would send to server in real implementation
    notifyListeners();
  }
  
  void acceptFriendRequest(String username) {
    _friendRequests.remove(username);
    addFriend(username);
  }
  
  void declineFriendRequest(String username) {
    _friendRequests.remove(username);
    saveProfile();
    notifyListeners();
  }
  
  // Theme management
  void unlockTheme(String themeId) {
    if (!_unlockedThemes.contains(themeId)) {
      _unlockedThemes.add(themeId);
      saveProfile();
      notifyListeners();
    }
  }
  
  void setTheme(String themeId, Color color) {
    _currentTheme = themeId;
    _boardColor = color;
    saveProfile();
    notifyListeners();
  }
  
  // Ad-skip management
  bool skipAdsWithCoins(int hours, int cost) {
    if (spendCoins(cost)) {
      _adFreeUntil = DateTime.now().add(Duration(hours: hours));
      saveProfile();
      notifyListeners();
      return true;
    }
    return false;
  }
  
  // Serialization
  Map<String, dynamic> toJson() {
    return {
      'username': _username,
      'coins': _coins,
      'totalWins': _totalWins,
      'totalLosses': _totalLosses,
      'totalDraws': _totalDraws,
      'winStreak': _winStreak,
      'bestStreak': _bestStreak,
      'isPro': _isPro,
      'lastLoginDate': _lastLoginDate?.toIso8601String(),
      'consecutiveLogins': _consecutiveLogins,
      'boardTheme': _boardTheme,
      'player1Color': _player1Color.value,
      'player2Color': _player2Color.value,
      'boardColor': _boardColor.value,
      'soundEnabled': _soundEnabled,
      'musicEnabled': _musicEnabled,
      'vibrateEnabled': _vibrateEnabled,
      'difficulty': _difficulty,
      'friends': _friends,
      'friendRequests': _friendRequests,
      'unlockedThemes': _unlockedThemes,
      'currentTheme': _currentTheme,
      'adFreeUntil': _adFreeUntil?.toIso8601String(),
    };
  }
  
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final profile = UserProfile();
    profile._username = json['username'] ?? 'Player';
    profile._coins = json['coins'] ?? 100;
    profile._totalWins = json['totalWins'] ?? 0;
    profile._totalLosses = json['totalLosses'] ?? 0;
    profile._totalDraws = json['totalDraws'] ?? 0;
    profile._winStreak = json['winStreak'] ?? 0;
    profile._bestStreak = json['bestStreak'] ?? 0;
    profile._isPro = json['isPro'] ?? false;
    profile._lastLoginDate = json['lastLoginDate'] != null 
        ? DateTime.parse(json['lastLoginDate']) 
        : null;
    profile._consecutiveLogins = json['consecutiveLogins'] ?? 0;
    profile._boardTheme = json['boardTheme'] ?? 'classic';
    profile._player1Color = Color(json['player1Color'] ?? Colors.red.value);
    profile._player2Color = Color(json['player2Color'] ?? Colors.blue.value);
    profile._boardColor = Color(json['boardColor'] ?? const Color(0xFFD4A574).value);
    profile._soundEnabled = json['soundEnabled'] ?? true;
    profile._musicEnabled = json['musicEnabled'] ?? true;
    profile._vibrateEnabled = json['vibrateEnabled'] ?? true;
    profile._difficulty = json['difficulty'] ?? 'medium';
    profile._friends = List<String>.from(json['friends'] ?? []);
    profile._friendRequests = List<String>.from(json['friendRequests'] ?? []);
    profile._unlockedThemes = List<String>.from(json['unlockedThemes'] ?? ['default']);
    profile._currentTheme = json['currentTheme'] ?? 'default';
    profile._adFreeUntil = json['adFreeUntil'] != null 
        ? DateTime.parse(json['adFreeUntil']) 
        : null;
    return profile;
  }
}
