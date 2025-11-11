import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
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
  bool _isSearching = false;
  Timer? _refreshTimer;
  Timer? _matchmakingTimer;
  String? _currentUsername;
  int _matchmakingCountdown = 10;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _matchmakingTimer?.cancel();
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

  /// Smart matchmaking - tries to join existing game first, creates new one if none available
  Future<void> _startMatchmaking() async {
    if (_currentUsername == null) {
      _showErrorDialog('Ju lutem hyni në llogari për të luajtur online');
      return;
    }

    setState(() {
      _isSearching = true;
      _matchmakingCountdown = 10;
    });

    // First, try to find and join an available game
    await _loadAvailableSessions();
    
    // Filter out my own sessions
    final availableGames = _availableSessions
        .where((s) => s['host_username'] != _currentUsername && s['status'] == 'waiting')
        .toList();

    if (availableGames.isNotEmpty) {
      // Found a game! Join it immediately
      final game = availableGames.first;
      final sessionId = game['id'] ?? game['session_id'];
      final hostUsername = game['host_username'];
      
      setState(() {
        _isSearching = false;
      });
      
      await _joinSession(sessionId.toString(), hostUsername);
      return;
    }

    // No games found - create one and show matchmaking dialog with countdown
    _showMatchmakingDialog();
  }

  void _showMatchmakingDialog() async {
    // Create session in background
    String? sessionId;
    
    try {
      final result = await ApiService.createGameSession(
        hostUsername: _currentUsername!,
      );
      
      if (result != null && result['session_id'] != null) {
        sessionId = result['session_id'].toString();
      } else {
        if (mounted) {
          setState(() {
            _isSearching = false;
          });
          _showErrorDialog('Nuk u arrit të krijohet sesioni. Provoni përsëri.');
        }
        return;
      }
    } catch (e) {
      print('Error creating session: $e');
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
        _showErrorDialog('Nuk u arrit të krijohet sesioni. Provoni përsëri.');
      }
      return;
    }

    if (!mounted) return;

    // Show countdown dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Start countdown timer
          if (_matchmakingTimer == null || !_matchmakingTimer!.isActive) {
            _matchmakingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
              if (_matchmakingCountdown > 0) {
                setDialogState(() {
                  _matchmakingCountdown--;
                });
              } else {
                timer.cancel();
                if (mounted && Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                  setState(() {
                    _isSearching = false;
                  });
                  _showErrorDialog(
                    'Nuk u gjet asnjë lojtarë në ${_matchmakingCountdown + 10}s. Provoni përsëri ose ftoni një mik!',
                  );
                }
              }
            });
          }

          return WillPopScope(
            onWillPop: () async => false,
            child: AlertDialog(
              title: Row(
                children: const [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 16),
                  Text('Duke kërkuar lojtarë...'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Duke pritur që një lojtarë të bashkohet...',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$_matchmakingCountdown sekonda',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Kodi i sesionit:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    sessionId ?? '',
                    style: const TextStyle(fontSize: 18, color: Colors.teal),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _matchmakingTimer?.cancel();
                    Navigator.of(context).pop();
                    setState(() {
                      _isSearching = false;
                    });
                    // TODO: Cancel/delete the session from backend
                  },
                  child: const Text('Anulo'),
                ),
              ],
            ),
          );
        },
      ),
    );

    // Poll for players joining
    Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted || !_isSearching) {
        timer.cancel();
        return;
      }

      try {
        final sessions = await ApiService.getActiveSessions();
        final session = sessions.firstWhere(
          (s) => (s['id'] ?? s['session_id'] ?? '').toString() == sessionId,
          orElse: () => {},
        );

        if (session.isNotEmpty) {
          final status = session['status'] ?? 'waiting';
          
          if (status == 'active' || status == 'in_progress') {
            // Player joined!
            timer.cancel();
            _matchmakingTimer?.cancel();
            
            if (mounted && Navigator.of(context).canPop()) {
              Navigator.of(context).pop(); // Close dialog
              
              final guestUsername = session['guest_username'] ?? '';
              
              setState(() {
                _isSearching = false;
              });
              
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => GameScreen(
                    mode: 'online',
                    sessionId: sessionId,
                    opponentUsername: guestUsername,
                  ),
                ),
              );
            }
          }
        }
      } catch (e) {
        print('Error polling session: $e');
      }
    });
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
        final sessionId = result['session_id'].toString();
        setState(() {
          _isCreatingSession = false;
        });

        // Show waiting dialog until another player joins
        _showWaitingDialog(sessionId, isHost: true);
      } else {
        throw Exception('Failed to create session');
      }
    } catch (e) {
      print('Error creating session: $e');
      if (mounted) {
        setState(() {
          _isCreatingSession = false;
        });
        _showErrorDialog('Nuk u arrit të krijohet sesioni i lojës. Ju lutem provoni përsëri.');
      }
    }
  }

  void _showWaitingDialog(String sessionId, {required bool isHost}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          title: Row(
            children: const [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 16),
              Text('Duke pritur...'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isHost 
                    ? 'Duke pritur që një lojtarë të bashkohet...'
                    : 'Duke u lidhur me lojtarin tjetër...',
              ),
              const SizedBox(height: 16),
              const Text(
                'Kodi i sesionit:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                sessionId,
                style: const TextStyle(fontSize: 18, color: Colors.teal),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Anulo'),
            ),
          ],
        ),
      ),
    );

    // Poll session status every 2 seconds
    Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      try {
        final sessions = await ApiService.getActiveSessions();
        
        // Debug: Print all sessions
        print('📋 Polling sessions. Total available: ${sessions.length}');
        print('🔍 Looking for session: $sessionId');
        
        final session = sessions.firstWhere(
          (s) {
            final sId = (s['id'] ?? s['session_id'] ?? '').toString();
            print('  Checking session: $sId (status: ${s['status']})');
            return sId == sessionId;
          },
          orElse: () => {},
        );

        if (session.isEmpty) {
          print('❌ Session not found in active sessions list');
          timer.cancel();
          if (mounted && Navigator.of(context).canPop()) {
            Navigator.of(context).pop(); // Close waiting dialog
            _showErrorDialog('Sesioni u mbyll, skadoi ose nuk u gjet. Ju lutem krijoni një lojë të re ose bashkohuni në një tjetër.');
          }
          return;
        }

        final status = session['status'] ?? 'waiting';
        print('📊 Session status: $status');
        
        if (status == 'active' || status == 'in_progress') {
          // Both players have joined - start the game!
          timer.cancel();
          if (mounted && Navigator.of(context).canPop()) {
            Navigator.of(context).pop(); // Close waiting dialog
            
            // Get opponent username
            final hostUsername = session['host_username'] ?? '';
            final guestUsername = session['guest_username'] ?? '';
            final opponentUsername = isHost ? guestUsername : hostUsername;
            
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => GameScreen(
                  mode: 'online',
                  sessionId: sessionId,
                  opponentUsername: opponentUsername,
                ),
              ),
            );
          }
        }
      } catch (e) {
        print('Error polling session: $e');
      }
    });
  }

  Future<void> _joinSession(String sessionId, String hostUsername) async {
    if (_currentUsername == null) {
      _showErrorDialog('Ju lutem hyni në llogari për të bashkuar në një lojë');
      return;
    }

    if (_currentUsername == hostUsername) {
      _showErrorDialog('Nuk mund të bashkoheni në lojën tuaj');
      return;
    }

    try {
      final result = await ApiService.joinGameSession(sessionId, _currentUsername!);
      
      if (result != null && mounted) {
        // Show brief waiting dialog then navigate to game
        _showWaitingDialog(sessionId, isHost: false);
      } else {
        _showErrorDialog('Nuk u arrit të bashkoheni në sesion. Mund të jetë plot ose jo më në dispozicion.');
      }
    } catch (e) {
      print('Error joining session: $e');
      _showErrorDialog('Nuk u arrit të bashkoheni në sesionin e lojës. Ju lutem provoni përsëri.');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gabim'),
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
        title: const Text('Shumëlojtarësh'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAvailableSessions,
            tooltip: 'Rifresko',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildLobbyContent(),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Quick Match button (primary action)
          FloatingActionButton.extended(
            heroTag: 'quickMatch',
            onPressed: _isSearching || _isCreatingSession ? null : _startMatchmaking,
            backgroundColor: Colors.orange,
            icon: _isSearching
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.flash_on),
            label: Text(_isSearching ? 'Duke kërkuar...' : 'Lojë e shpejtë'),
          ),
          const SizedBox(height: 12),
          // Manual create game button (secondary)
          FloatingActionButton.extended(
            heroTag: 'createGame',
            onPressed: _isCreatingSession || _isSearching ? null : _createNewSession,
            backgroundColor: Colors.teal,
            icon: _isCreatingSession
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.add),
            label: Text(_isCreatingSession ? 'Duke krijuar...' : 'Krijo lojë'),
          ),
        ],
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
              'Nuk ka lojëra të disponueshme',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Krijo një lojë të re për të filluar!',
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
    final hostUsername = session['host_username'] ?? 'Pa emër';
    final status = session['status'] ?? 'waiting';
    final createdAt = session['created_at'];
    
    // Parse created time
    String timeAgo = 'Sapo tani';
    if (createdAt != null) {
      try {
        final createdTime = DateTime.parse(createdAt);
        final difference = DateTime.now().difference(createdTime);
        if (difference.inMinutes < 1) {
          timeAgo = 'Sapo tani';
        } else if (difference.inMinutes < 60) {
          timeAgo = '${difference.inMinutes} min më parë';
        } else {
          timeAgo = '${difference.inHours} orë më parë';
        }
      } catch (e) {
        // Keep default "Sapo tani"
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
          'Pritës: $hostUsername',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Statusi: ${_formatStatus(status)}'),
            const SizedBox(height: 2),
            Text(
              'Krijuar $timeAgo',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: isMySession
            ? Chip(
                label: const Text('Loja juaj'),
                backgroundColor: Colors.green[100],
                labelStyle: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              )
            : ElevatedButton.icon(
                onPressed: () => _joinSession(sessionId.toString(), hostUsername),
                icon: const Icon(Icons.login, size: 18),
                label: const Text('Bashkohu'),
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
        return '🟡 Duke pritur lojtarë';
      case 'active':
      case 'in_progress':
        return '🟢 Në progres';
      case 'finished':
        return '⚪ Përfunduar';
      default:
        return status;
    }
  }
}
