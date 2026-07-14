import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_keys.dart';

class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final int pointsRequired;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.pointsRequired,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] ?? json['achievement_id'],
      title: json['title'],
      description: json['description'],
      icon: json['icon'],
      pointsRequired: json['points_required'] ?? 0,
      isUnlocked: json['is_unlocked'] ?? false,
      unlockedAt: json['unlocked_at'] != null 
          ? DateTime.parse(json['unlocked_at']) 
          : null,
    );
  }
}

class AchievementsService {
  static final AchievementsService _instance = AchievementsService._internal();
  factory AchievementsService() => _instance;
  AchievementsService._internal();

  static String get baseUrl => ApiKeys.currentServerUrl;

  // Predefined achievements
  static final List<Map<String, dynamic>> defaultAchievements = [
    {
      'id': 'first_win',
      'title': 'Fitorja e Parë',
      'description': 'Fitoni lojën tuaj të parë',
      'icon': '🏆',
      'points_required': 1,
    },
    {
      'id': 'win_streak_5',
      'title': 'Seri Fitore 5',
      'description': 'Fitoni 5 lojëra në seri',
      'icon': '🔥',
      'points_required': 5,
    },
    {
      'id': 'win_streak_10',
      'title': 'Seri Fitore 10',
      'description': 'Fitoni 10 lojëra në seri',
      'icon': '⚡',
      'points_required': 10,
    },
    {
      'id': 'games_100',
      'title': 'Veteran',
      'description': 'Luani 100 lojëra',
      'icon': '🎮',
      'points_required': 100,
    },
    {
      'id': 'games_500',
      'title': 'Mjeshtër',
      'description': 'Luani 500 lojëra',
      'icon': '👑',
      'points_required': 500,
    },
    {
      'id': 'level_10',
      'title': 'Nivel 10',
      'description': 'Arrini nivelin 10',
      'icon': '⭐',
      'points_required': 10,
    },
    {
      'id': 'level_50',
      'title': 'Nivel 50',
      'description': 'Arrini nivelin 50',
      'icon': '💎',
      'points_required': 50,
    },
    {
      'id': 'pro_member',
      'title': 'Anëtar PRO',
      'description': 'Blini pajtimin PRO',
      'icon': '👔',
      'points_required': 1,
    },
    {
      'id': 'coins_1000',
      'title': 'I Pasur',
      'description': 'Mblidhni 1000 monedha',
      'icon': '💰',
      'points_required': 1000,
    },
    {
      'id': 'friend_10',
      'title': 'Popullor',
      'description': 'Shtoni 10 miq',
      'icon': '👥',
      'points_required': 10,
    },
  ];

  // Get all achievements for a user
  Future<List<Achievement>> getUserAchievements(String username) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/achievements?username=$username'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final achievements = (data['achievements'] as List)
            .map((a) => Achievement.fromJson(a))
            .toList();
        return achievements;
      } else {
        debugPrint('Failed to get achievements: ${response.statusCode}');
        return _getDefaultAchievements();
      }
    } catch (e) {
      debugPrint('Error getting achievements: $e');
      return _getDefaultAchievements();
    }
  }

  // Get default achievements (all locked)
  List<Achievement> _getDefaultAchievements() {
    return defaultAchievements
        .map((a) => Achievement.fromJson(a))
        .toList();
  }

  // Check and unlock achievements after a game
  Future<List<Achievement>> checkAndUnlockAchievements({
    required String username,
    required int totalWins,
    required int currentWinStreak,
    required int totalGames,
    required int userLevel,
    required int coins,
    required int friendsCount,
    required bool isPro,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/achievements'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': 'check_unlock',
          'username': username,
          'total_wins': totalWins,
          'current_win_streak': currentWinStreak,
          'total_games': totalGames,
          'user_level': userLevel,
          'coins': coins,
          'friends_count': friendsCount,
          'is_pro': isPro,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newlyUnlocked = (data['newly_unlocked'] as List)
            .map((a) => Achievement.fromJson(a))
            .toList();
        return newlyUnlocked;
      } else {
        debugPrint('Failed to check achievements: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error checking achievements: $e');
      return [];
    }
  }

  // Manually unlock a specific achievement
  Future<bool> unlockAchievement({
    required String username,
    required String achievementId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/achievements'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': 'unlock',
          'username': username,
          'achievement_id': achievementId,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error unlocking achievement: $e');
      return false;
    }
  }

  // Get achievement progress
  Future<Map<String, dynamic>> getAchievementProgress(String username) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/achievements?username=$username&action=progress'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'total': defaultAchievements.length,
          'unlocked': 0,
          'percentage': 0,
        };
      }
    } catch (e) {
      debugPrint('Error getting achievement progress: $e');
      return {
        'total': defaultAchievements.length,
        'unlocked': 0,
        'percentage': 0,
      };
    }
  }
}
