import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../config/api_keys.dart';

class EmailService {
  static final EmailService _instance = EmailService._internal();
  factory EmailService() => _instance;
  EmailService._internal();

  static String get baseUrl => ApiKeys.currentServerUrl;

  // Send friend request notification
  Future<bool> sendFriendRequestEmail({
    required String toUsername,
    required String fromUsername,
  }) async {
    return await _sendEmail(
      type: 'friend_request',
      username: toUsername,
      data: {'from_username': fromUsername},
    );
  }

  // Send game invite notification
  Future<bool> sendGameInviteEmail({
    required String toUsername,
    required String fromUsername,
  }) async {
    return await _sendEmail(
      type: 'game_invite',
      username: toUsername,
      data: {'from_username': fromUsername},
    );
  }

  // Send achievement unlocked notification
  Future<bool> sendAchievementEmail({
    required String username,
    required String achievementTitle,
    required String achievementDescription,
    String? achievementIcon,
  }) async {
    return await _sendEmail(
      type: 'achievement_unlocked',
      username: username,
      data: {
        'achievement_title': achievementTitle,
        'achievement_description': achievementDescription,
        'achievement_icon': achievementIcon ?? '🏆',
      },
    );
  }

  // Send PRO purchase confirmation
  Future<bool> sendProPurchaseEmail({
    required String username,
    required int months,
    required String amount,
  }) async {
    return await _sendEmail(
      type: 'pro_purchase',
      username: username,
      data: {
        'months': months,
        'amount': amount,
      },
    );
  }

  // Send coins purchase confirmation
  Future<bool> sendCoinsPurchaseEmail({
    required String username,
    required int coins,
    required String amount,
  }) async {
    return await _sendEmail(
      type: 'coins_purchase',
      username: username,
      data: {
        'coins': coins,
        'amount': amount,
      },
    );
  }

  // Send password reset email
  Future<bool> sendPasswordResetEmail({
    required String username,
    required String resetToken,
  }) async {
    return await _sendEmail(
      type: 'password_reset',
      username: username,
      data: {
        'reset_token': resetToken,
      },
    );
  }

  // Internal method to send email via API
  Future<bool> _sendEmail({
    required String type,
    required String username,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/email'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'type': type,
          'username': username,
          'data': data,
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('Email sent successfully: $type to $username');
        return true;
      } else {
        debugPrint('Failed to send email: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error sending email: $e');
      return false;
    }
  }
}
