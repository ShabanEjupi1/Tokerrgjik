import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/sound_service.dart';
import 'game_screen.dart';

/// Multiplayer Lobby Screen
/// Shows available game sessions and allows players to create or join games
class MultiplayerLobbyScreen extends StatefulWidget {
  const MultiplayerLobbyScreen({Key? key}) : super(key: key);

  @override
  State<MultiplayerLobbyScreen> createState() => _MultiplayerLobbyScreenState();
}

class _MultiplayerLobbyScreenState extends State<MultiplayerLobbyScreen> {
  List<Map<String, dynamic>> _availableSessions = [];
  bool _isLoading = true;
  bool _isCreatingSession = false;
  Timer? _refreshTimer;
  String? _currentUsername;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeScreen() async {
    setState(() {
      _currentUsername = AuthService.currentUsername;
    });
    
    await _loadAvailableSessions();
    
    // Auto-refresh every 5 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _loadAvailableSessions();
    });
  }

  Future<void> _loadAvailableSessions() async {
    try {
      final sessions = await ApiService.getActiveSessions();
      if (mounted) {
        setState(() {
          _availableSessions = sessions;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading sessions: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _createNewSession() async {
    if (_currentUsername == null) {
      _showErrorDialog('Please log in to create a game session');
      return;
    }

    setState(() {
      _isCreatingSession = true;
    });

    try {
      final result = await ApiService.createGameSession(
        hostUsername: _currentUsername!,
      );
      
      if (result != null && result['session_id'] != null && mounted) {
        setState(() {
          _isCreatingSession = false;
        });

        // Navigate to game screen as host
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const GameScreen(
              mode: 'online',
            ),
          ),
        );
      } else {
        throw Exception('Failed to create session');
      }
    } catch (e) {
      print('Error creating session: $e');
      if (mounted) {
        setState(() {
          _isCreatingSession = false;
        });
        _showErrorDialog('Failed to create game session. Please try again.');
      }
    }
  }

  Future<void> _joinSession(String sessionId, String hostUsername) async {
    if (_currentUsername == null) {
      _showErrorDialog('Please log in to join a game');
      return;
    }

    if (_currentUsername == hostUsername) {
      _showErrorDialog('You cannot join your own game session');
      return;
    }

    try {
      final result = await ApiService.joinGameSession(sessionId, _currentUsername!);
      
      if (result != null && mounted) {
        // Navigate to game screen as guest
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const GameScreen(
              mode: 'online',
            ),
          ),
        );
      } else {
        _showErrorDialog('Failed to join session. It may be full or no longer available.');
      }
    } catch (e) {
      print('Error joining session: $e');
      _showErrorDialog('Failed to join game session. Please try again.');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Multiplayer'),
        backgroundColor: Colors.teal, // Changed from deepPurple
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAvailableSessions,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildLobbyContent(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isCreatingSession ? null : _createNewSession,
        backgroundColor: Colors.teal, // Changed from deepPurple
        icon: _isCreatingSession
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : const Icon(Icons.add),
        label: Text(_isCreatingSession ? 'Creating...' : 'Create game'),
      ),
    );
  }

  Widget _buildLobbyContent() {
    if (_availableSessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sports_esports_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No games available',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a new game to get started!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _availableSessions.length,
      itemBuilder: (context, index) {
        final session = _availableSessions[index];
        return _buildSessionCard(session);
      },
    );
  }

  Widget _buildSessionCard(Map<String, dynamic> session) {
    final sessionId = session['id'] ?? session['session_id'] ?? 'unknown';
    final hostUsername = session['host_username'] ?? 'Unknown';
    final status = session['status'] ?? 'waiting';
    final createdAt = session['created_at'];
    
    // Parse created time
    String timeAgo = 'Just now';
    if (createdAt != null) {
      try {
        final createdTime = DateTime.parse(createdAt);
        final difference = DateTime.now().difference(createdTime);
        if (difference.inMinutes < 1) {
          timeAgo = 'Just now';
        } else if (difference.inMinutes < 60) {
          timeAgo = '${difference.inMinutes}m ago';
        } else {
          timeAgo = '${difference.inHours}h ago';
        }
      } catch (e) {
        // Keep default "Just now"
      }
    }

    final isMySession = hostUsername == _currentUsername;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: isMySession ? Colors.green : Colors.teal, // Changed from deepPurple
          radius: 30,
          child: Icon(
            isMySession ? Icons.person : Icons.sports_esports,
            color: Colors.white,
            size: 30,
          ),
        ),
        title: Text(
          'Host: $hostUsername',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Status: ${_formatStatus(status)}'),
            const SizedBox(height: 2),
            Text(
              'Created $timeAgo',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: isMySession
            ? Chip(
                label: const Text('Your Game'),
                backgroundColor: Colors.green[100],
                labelStyle: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              )
            : ElevatedButton.icon(
                onPressed: () => _joinSession(sessionId.toString(), hostUsername),
                icon: const Icon(Icons.login, size: 18),
                label: const Text('Join'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal, // Changed from deepPurple
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
      ),
    );
  }

  String _formatStatus(String status) {
    switch (status.toLowerCase()) {
      case 'waiting':
        return '🟡 Waiting for player';
      case 'active':
        return '🟢 In progress';
      case 'finished':
        return '⚪ Finished';
      default:
        return status;
    }
  }
}
