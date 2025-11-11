import 'dart:async';
import 'package:flutter/material.dart';
import '../services/challenges_service.dart';
import '../services/auth_service.dart';
import '../services/sound_service.dart';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _receivedChallenges = [];
  List<Map<String, dynamic>> _sentChallenges = [];
  bool _isLoading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadChallenges();

    // Auto-refresh every 10 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        _loadChallenges();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadChallenges() async {
    setState(() => _isLoading = true);

    try {
      final received = await ChallengesService.getPendingChallenges();
      final sent = await ChallengesService.getSentChallenges();

      if (mounted) {
        setState(() {
          _receivedChallenges = received;
          _sentChallenges = sent;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading challenges: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('⚔️ Sfidat'),
        backgroundColor: const Color(0xFFE74C3C),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadChallenges,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.inbox),
              text: 'Të pranuara (${_receivedChallenges.length})',
            ),
            Tab(
              icon: const Icon(Icons.send),
              text: 'Të dërguara (${_sentChallenges.length})',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReceivedChallenges(),
          _buildSentChallenges(),
        ],
      ),
    );
  }

  Widget _buildReceivedChallenges() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_receivedChallenges.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.inbox, size: 80, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Nuk keni sfida të reja',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadChallenges,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _receivedChallenges.length,
        itemBuilder: (context, index) {
          final challenge = _receivedChallenges[index];
          return _buildReceivedChallengeCard(challenge);
        },
      ),
    );
  }

  Widget _buildReceivedChallengeCard(Map<String, dynamic> challenge) {
    final fromUsername = challenge['from_username'] ?? 'Unknown';
    final createdAt = challenge['created_at'] != null
        ? DateTime.parse(challenge['created_at'])
        : DateTime.now();
    final timeAgo = _getTimeAgo(createdAt);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: const Color(0xFF3498DB),
                  child: Text(
                    fromUsername[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fromUsername,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Level ${challenge['from_level'] ?? '?'} • ${challenge['from_wins'] ?? 0} fitore',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.swords, color: Color(0xFFE74C3C), size: 30),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Dërguar $timeAgo',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _declineChallenge(challenge),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Refuzo'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _acceptChallenge(challenge),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Prano'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF27AE60),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSentChallenges() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_sentChallenges.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.send, size: 80, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Nuk keni dërguar sfida',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadChallenges,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _sentChallenges.length,
        itemBuilder: (context, index) {
          final challenge = _sentChallenges[index];
          return _buildSentChallengeCard(challenge);
        },
      ),
    );
  }

  Widget _buildSentChallengeCard(Map<String, dynamic> challenge) {
    final toUsername = challenge['to_username'] ?? 'Unknown';
    final createdAt = challenge['created_at'] != null
        ? DateTime.parse(challenge['created_at'])
        : DateTime.now();
    final timeAgo = _getTimeAgo(createdAt);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: const Color(0xFF9B59B6),
                  child: Text(
                    toUsername[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        toUsername,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Level ${challenge['to_level'] ?? '?'} • ${challenge['to_wins'] ?? 0} fitore',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.hourglass_empty,
                    color: Colors.orange, size: 30),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Dërguar $timeAgo • Duke pritur përgjigje...',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _cancelChallenge(challenge),
                  icon: const Icon(Icons.cancel, size: 18),
                  label: const Text('Anulo'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey,
                    side: BorderSide(color: Colors.grey[400]!),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'tani';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minuta më parë';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} orë më parë';
    } else {
      return '${difference.inDays} ditë më parë';
    }
  }

  Future<void> _acceptChallenge(Map<String, dynamic> challenge) async {
    SoundService.playClick();

    final username = AuthService.currentUsername;
    if (username == null) return;

    final challengeId = challenge['id']?.toString();
    if (challengeId == null) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final success = await ChallengesService.acceptChallenge(
        challengeId: challengeId,
        username: username,
      );

      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        if (success) {
          SoundService.playSuccess();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Sfida u pranua! Duke filluar lojën...'),
              backgroundColor: Colors.green,
            ),
          );

          // Refresh challenges
          await _loadChallenges();

          // Get session ID and navigate to game
          final sessionId = challenge['session_id'];
          if (sessionId != null) {
            Navigator.pushNamed(
              context,
              '/multiplayer_game',
              arguments: {'session_id': sessionId},
            );
          }
        } else {
          _showError('Nuk u arrit të pranohej sfida');
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showError('Gabim: $e');
      }
    }
  }

  Future<void> _declineChallenge(Map<String, dynamic> challenge) async {
    SoundService.playClick();

    final username = AuthService.currentUsername;
    if (username == null) return;

    final challengeId = challenge['id']?.toString();
    if (challengeId == null) return;

    final success = await ChallengesService.declineChallenge(
      challengeId: challengeId,
      username: username,
    );

    if (success) {
      SoundService.playMove();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sfida u refuzua'),
          backgroundColor: Colors.orange,
        ),
      );
      await _loadChallenges();
    } else {
      _showError('Nuk u arrit të refuzohej sfida');
    }
  }

  Future<void> _cancelChallenge(Map<String, dynamic> challenge) async {
    SoundService.playClick();

    final username = AuthService.currentUsername;
    if (username == null) return;

    final challengeId = challenge['id']?.toString();
    if (challengeId == null) return;

    final success = await ChallengesService.cancelChallenge(
      challengeId: challengeId,
      username: username,
    );

    if (success) {
      SoundService.playMove();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sfida u anulua'),
        ),
      );
      await _loadChallenges();
    } else {
      _showError('Nuk u arrit të anulohej sfida');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ $message'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
