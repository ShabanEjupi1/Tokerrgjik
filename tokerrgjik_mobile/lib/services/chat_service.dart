import 'package:flutter/foundation.dart';

/// Chat Message Model
class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String message;
  final DateTime timestamp;
  final ChatMessageType type;
  final String? avatarUrl;
  final bool isMe;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.timestamp,
    this.type = ChatMessageType.text,
    this.avatarUrl,
    this.isMe = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json, String currentUserId) {
    return ChatMessage(
      id: json['id'] ?? '',
      senderId: json['sender_id'] ?? '',
      senderName: json['sender_name'] ?? 'Unknown',
      message: json['message'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      type: _parseMessageType(json['type']),
      avatarUrl: json['avatar_url'],
      isMe: json['sender_id'] == currentUserId,
    );
  }

  static ChatMessageType _parseMessageType(String? type) {
    switch (type) {
      case 'system':
        return ChatMessageType.system;
      case 'emote':
        return ChatMessageType.emote;
      case 'quick':
        return ChatMessageType.quick;
      default:
        return ChatMessageType.text;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'sender_name': senderName,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'type': type.toString().split('.').last,
      'avatar_url': avatarUrl,
    };
  }
}

/// Chat message types
enum ChatMessageType {
  text,
  system,
  emote,
  quick,
}

/// Chat Service
/// Manages in-game chat with message history, filtering, and moderation
class ChatService extends ChangeNotifier {
  final List<ChatMessage> _messages = [];
  final int _maxMessages = 100;
  final String _currentUserId;
  final String _currentUserName;
  
  bool _isEnabled = true;
  bool _showTimestamps = true;
  bool _filterProfanity = true;
  final Set<String> _mutedUsers = {};
  final Set<String> _blockedWords = {};

  // Callbacks
  Function(ChatMessage message)? onNewMessage;
  Function(String userId)? onUserMuted;
  Function(String userId)? onUserUnmuted;

  ChatService({
    required String currentUserId,
    required String currentUserName,
  })  : _currentUserId = currentUserId,
        _currentUserName = currentUserName {
    _initializeProfanityFilter();
  }

  /// Initialize profanity filter with common words
  void _initializeProfanityFilter() {
    // Add basic profanity filter words
    // In production, load from a more comprehensive list
    _blockedWords.addAll([
      'damn',
      'hell',
      // Add more as needed
    ]);
  }

  // ==================== MESSAGE MANAGEMENT ====================

  /// Get all messages
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  /// Get messages count
  int get messageCount => _messages.length;

  /// Get last message
  ChatMessage? get lastMessage => _messages.isNotEmpty ? _messages.last : null;

  /// Add a new message
  void addMessage(ChatMessage message) {
    // Check if user is muted
    if (_mutedUsers.contains(message.senderId)) {
      return;
    }

    // Filter profanity if enabled
    if (_filterProfanity && !message.isMe) {
      message = ChatMessage(
        id: message.id,
        senderId: message.senderId,
        senderName: message.senderName,
        message: _filterMessage(message.message),
        timestamp: message.timestamp,
        type: message.type,
        avatarUrl: message.avatarUrl,
        isMe: message.isMe,
      );
    }

    _messages.add(message);

    // Limit message history
    if (_messages.length > _maxMessages) {
      _messages.removeAt(0);
    }

    onNewMessage?.call(message);
    notifyListeners();
  }

  /// Add text message from current user
  void sendMessage(String text) {
    if (text.trim().isEmpty || !_isEnabled) return;

    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: _currentUserId,
      senderName: _currentUserName,
      message: text.trim(),
      timestamp: DateTime.now(),
      type: ChatMessageType.text,
      isMe: true,
    );

    addMessage(message);
  }

  /// Add system message
  void addSystemMessage(String text) {
    final message = ChatMessage(
      id: 'system_${DateTime.now().millisecondsSinceEpoch}',
      senderId: 'system',
      senderName: 'System',
      message: text,
      timestamp: DateTime.now(),
      type: ChatMessageType.system,
      isMe: false,
    );

    addMessage(message);
  }

  /// Add quick chat message
  void sendQuickChat(String quickChatId) {
    final quickMessage = _getQuickChatMessage(quickChatId);
    if (quickMessage == null) return;

    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: _currentUserId,
      senderName: _currentUserName,
      message: quickMessage,
      timestamp: DateTime.now(),
      type: ChatMessageType.quick,
      isMe: true,
    );

    addMessage(message);
  }

  /// Add emote message
  void sendEmote(String emoteId) {
    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: _currentUserId,
      senderName: _currentUserName,
      message: emoteId,
      timestamp: DateTime.now(),
      type: ChatMessageType.emote,
      isMe: true,
    );

    addMessage(message);
  }

  /// Process incoming message from server
  void processIncomingMessage(Map<String, dynamic> data) {
    try {
      final message = ChatMessage.fromJson(data, _currentUserId);
      addMessage(message);
    } catch (e) {
      print('ChatService: Error processing message: $e');
    }
  }

  /// Clear all messages
  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }

  /// Delete specific message
  void deleteMessage(String messageId) {
    _messages.removeWhere((msg) => msg.id == messageId);
    notifyListeners();
  }

  // ==================== USER MODERATION ====================

  /// Mute a user
  void muteUser(String userId) {
    _mutedUsers.add(userId);
    // Remove existing messages from muted user
    _messages.removeWhere((msg) => msg.senderId == userId);
    onUserMuted?.call(userId);
    notifyListeners();
  }

  /// Unmute a user
  void unmuteUser(String userId) {
    _mutedUsers.remove(userId);
    onUserUnmuted?.call(userId);
    notifyListeners();
  }

  /// Check if user is muted
  bool isUserMuted(String userId) {
    return _mutedUsers.contains(userId);
  }

  /// Get list of muted users
  List<String> get mutedUsers => List.unmodifiable(_mutedUsers);

  // ==================== SETTINGS ====================

  /// Enable/disable chat
  bool get isEnabled => _isEnabled;
  set isEnabled(bool value) {
    _isEnabled = value;
    notifyListeners();
  }

  /// Show/hide timestamps
  bool get showTimestamps => _showTimestamps;
  set showTimestamps(bool value) {
    _showTimestamps = value;
    notifyListeners();
  }

  /// Enable/disable profanity filter
  bool get filterProfanity => _filterProfanity;
  set filterProfanity(bool value) {
    _filterProfanity = value;
    notifyListeners();
  }

  // ==================== PROFANITY FILTER ====================

  /// Filter message for profanity
  String _filterMessage(String message) {
    String filtered = message;
    
    for (final word in _blockedWords) {
      final regex = RegExp(word, caseSensitive: false);
      filtered = filtered.replaceAllMapped(regex, (match) {
        return '*' * match.group(0)!.length;
      });
    }
    
    return filtered;
  }

  /// Add word to blocked list
  void addBlockedWord(String word) {
    _blockedWords.add(word.toLowerCase());
  }

  /// Remove word from blocked list
  void removeBlockedWord(String word) {
    _blockedWords.remove(word.toLowerCase());
  }

  // ==================== QUICK CHAT ====================

  /// Get quick chat message by ID
  String? _getQuickChatMessage(String id) {
    return _quickChatMessages[id];
  }

  /// Available quick chat messages
  static const Map<String, String> _quickChatMessages = {
    'hello': '👋 Hello!',
    'gg': '🎮 Good game!',
    'gl': '🍀 Good luck!',
    'nice': '👍 Nice move!',
    'oops': '😅 Oops!',
    'thinking': '🤔 Thinking...',
    'thanks': '🙏 Thanks!',
    'wow': '😮 Wow!',
    'sorry': '😔 Sorry!',
    'brb': '⏱️ Be right back',
    'afk': '💤 Away from keyboard',
    'ready': '✅ Ready!',
    'wait': '⏳ Wait please',
    'hurry': '⏰ Hurry up!',
    'excellent': '🌟 Excellent!',
  };

  static Map<String, String> get quickChatMessages => _quickChatMessages;

  // ==================== EMOTES ====================

  /// Available emotes
  static const List<String> emotes = [
    '😀', '😁', '😂', '🤣', '😃', '😄', '😅', '😆',
    '😉', '😊', '😋', '😎', '😍', '😘', '😗', '😙',
    '😚', '🙂', '🤗', '🤔', '😐', '😑', '😶', '🙄',
    '😏', '😣', '😥', '😮', '🤐', '😯', '😪', '😫',
    '😴', '😌', '😛', '😜', '😝', '🤤', '😒', '😓',
    '😔', '😕', '🙃', '🤑', '😲', '☹️', '🙁', '😖',
    '😞', '😟', '😤', '😢', '😭', '😦', '😧', '😨',
    '😩', '🤯', '😬', '😰', '😱', '😳', '🤪', '😵',
    '👍', '👎', '👊', '✊', '🤛', '🤜', '🤞', '✌️',
    '🤟', '🤘', '👌', '👈', '👉', '👆', '👇', '☝️',
    '✋', '🤚', '🖐️', '🖖', '👋', '🤙', '💪', '🙏',
    '🎮', '🎯', '🎲', '🏆', '🥇', '🥈', '🥉', '⭐',
    '🔥', '💯', '⚡', '💥', '✨', '🌟', '💫', '🎉',
  ];

  // ==================== EXPORT/IMPORT ====================

  /// Export chat history
  List<Map<String, dynamic>> exportHistory() {
    return _messages.map((msg) => msg.toJson()).toList();
  }

  /// Import chat history
  void importHistory(List<Map<String, dynamic>> history) {
    _messages.clear();
    for (final data in history) {
      try {
        final message = ChatMessage.fromJson(data, _currentUserId);
        _messages.add(message);
      } catch (e) {
        print('ChatService: Error importing message: $e');
      }
    }
    notifyListeners();
  }

  /// Dispose service
  @override
  void dispose() {
    _messages.clear();
    _mutedUsers.clear();
    super.dispose();
  }
}
