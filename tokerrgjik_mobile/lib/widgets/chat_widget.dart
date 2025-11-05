import 'package:flutter/material.dart';
import 'package:tokerrgjik_mobile/services/socket_service.dart';
import '../services/chat_service.dart';

/// Enhanced Chat Widget for in-game messaging
/// Integrates with both ChatService and SocketService
class ChatWidget extends StatefulWidget {
  final SocketService socketService;
  final bool isMinimized;
  final VoidCallback? onToggleMinimize;

  const ChatWidget({
    super.key,
    required this.socketService,
    this.isMinimized = false,
    this.onToggleMinimize,
  });

  @override
  State<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {
  final _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showQuickChat = false;

  @override
  void initState() {
    super.initState();
    // Listen for chat messages from the server
  }

  @override
  void dispose() {
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _sendMessage() {
    if (_chatController.text.isEmpty) return;
    
    widget.socketService.sendChatMessage(_chatController.text);
    _chatController.clear();
    _scrollToBottom();
  }

  void _sendQuickChat(String message) {
    widget.socketService.sendChatMessage(message);
    setState(() => _showQuickChat = false);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isMinimized) {
      return _buildMinimized();
    }

    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildMessageList()),
          if (_showQuickChat) _buildQuickChatPanel(),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMinimized() {
    return GestureDetector(
      onTap: widget.onToggleMinimize,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.teal, // Changed from deepPurple
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble, color: Colors.white, size: 18),
            SizedBox(width: 6),
            Text(
              'Chat',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.teal, // Changed from deepPurple
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          const Icon(Icons.chat_bubble, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          const Text(
            'Chat',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          if (widget.onToggleMinimize != null)
            IconButton(
              icon: const Icon(Icons.expand_more, color: Colors.white, size: 20),
              onPressed: widget.onToggleMinimize,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    // For now, use a simple list. Can be enhanced with ChatService
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8.0),
      itemCount: 0, // Will be populated with actual messages
      itemBuilder: (context, index) => const Text(''),
    );
  }

  Widget _buildQuickChatPanel() {
    final quickChats = ChatService.quickChatMessages;
    
    return Container(
      height: 100,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 2.5,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: 6, // Show first 6 quick chats
        itemBuilder: (context, index) {
          final entry = quickChats.entries.elementAt(index);
          return ElevatedButton(
            onPressed: () => _sendQuickChat(entry.value),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              textStyle: const TextStyle(fontSize: 11),
            ),
            child: Text(entry.value, textAlign: TextAlign.center, maxLines: 1),
          );
        },
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              _showQuickChat ? Icons.keyboard : Icons.flash_on,
              color: Colors.teal, // Changed from deepPurple
              size: 20,
            ),
            onPressed: () {
              setState(() => _showQuickChat = !_showQuickChat);
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _chatController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: const TextStyle(fontSize: 13),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
              maxLength: 200,
              buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.teal, size: 20), // Changed from deepPurple
            onPressed: _sendMessage,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
