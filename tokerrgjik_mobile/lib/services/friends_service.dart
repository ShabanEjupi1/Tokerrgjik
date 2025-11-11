import 'api_service.dart';

/// Friends Service for managing friendships
/// Updated: 2025-11-05 - Fixed ApiService.delete() return type handling
class FriendsService {
  /// Send friend request
  static Future<Map<String, dynamic>?> sendFriendRequest({
    required String fromUsername,
    required String toUsername,
  }) async {
    try {
      final result = await ApiService.post('/friends', {
        'action': 'send_request',
        'user_username': fromUsername,
        'friend_username': toUsername,
      });

      return result;
    } catch (e) {
      print('Error sending friend request: $e');
      return null;
    }
  }

  /// Accept friend request
  static Future<Map<String, dynamic>?> acceptFriendRequest({
    required String username,
    required String friendUsername,
  }) async {
    try {
      final result = await ApiService.post('/friends', {
        'action': 'accept',
        'user_username': username,
        'friend_username': friendUsername,
      });

      return result;
    } catch (e) {
      print('Error accepting friend request: $e');
      return null;
    }
  }

  /// Reject friend request
  static Future<Map<String, dynamic>?> rejectFriendRequest({
    required String username,
    required String friendUsername,
  }) async {
    try {
      final result = await ApiService.post('/friends', {
        'action': 'reject',
        'user_username': username,
        'friend_username': friendUsername,
      });

      return result;
    } catch (e) {
      print('Error rejecting friend request: $e');
      return null;
    }
  }

  /// Get friends list
  static Future<List<Map<String, dynamic>>> getFriends(String username) async {
    try {
      final result = await ApiService.get('/friends?username=$username&action=list');
      
      if (result != null && result['friends'] != null) {
        return List<Map<String, dynamic>>.from(result['friends']);
      }
      return [];
    } catch (e) {
      print('Error getting friends: $e');
      return [];
    }
  }

  /// Get pending friend requests (received)
  static Future<List<Map<String, dynamic>>> getPendingRequests(String username) async {
    try {
      final result = await ApiService.get('/friends?username=$username&action=pending');
      
      if (result != null && result['pending_requests'] != null) {
        return List<Map<String, dynamic>>.from(result['pending_requests']);
      }
      return [];
    } catch (e) {
      print('Error getting pending requests: $e');
      return [];
    }
  }

  /// Get sent friend requests
  static Future<List<Map<String, dynamic>>> getSentRequests(String username) async {
    try {
      final result = await ApiService.get('/friends?username=$username&action=sent');
      
      if (result != null && result['sent_requests'] != null) {
        return List<Map<String, dynamic>>.from(result['sent_requests']);
      }
      return [];
    } catch (e) {
      print('Error getting sent requests: $e');
      return [];
    }
  }

  /// Get friend count
  static Future<int> getFriendCount(String username) async {
    try {
      final result = await ApiService.get('/friends?username=$username&action=count');
      
      if (result != null && result['friends_count'] != null) {
        return result['friends_count'] as int;
      }
      return 0;
    } catch (e) {
      print('Error getting friend count: $e');
      return 0;
    }
  }

  /// Remove friend
  static Future<bool> removeFriend({
    required String username,
    required String friendUsername,
  }) async {
    try {
      final result = await ApiService.delete(
        '/friends?user_username=$username&friend_username=$friendUsername'
      );

      return result != null && result['success'] == true;
    } catch (e) {
      print('Error removing friend: $e');
      return false;
    }
  }

  /// Search users (for adding friends)
  static Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      final result = await ApiService.get('/users/search?q=$query');
      
      if (result != null && result['users'] != null) {
        return List<Map<String, dynamic>>.from(result['users']);
      }
      return [];
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }
}
