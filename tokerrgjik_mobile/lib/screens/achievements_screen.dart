import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_profile.dart';
import '../services/achievements_service.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({Key? key}) : super(key: key);

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  bool _isLoading = true;
  List<Achievement> _achievements = [];

  @override
  void initState() {
    super.initState();
    _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    setState(() => _isLoading = true);

    try {
      // Get default achievements
      final defaultAchievements = AchievementsService.defaultAchievements;
      final profile = Provider.of<UserProfile>(context, listen: false);

      // Create achievement objects and check if unlocked
      final achievements = defaultAchievements.map((data) {
        bool isUnlocked = _checkIfUnlocked(data['id'], profile);
        
        return Achievement(
          id: data['id'],
          title: data['title'],
          description: data['description'],
          icon: data['icon'],
          pointsRequired: data['points_required'],
          isUnlocked: isUnlocked,
        );
      }).toList();

      if (mounted) {
        setState(() {
          _achievements = achievements;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading achievements: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool _checkIfUnlocked(String achievementId, UserProfile profile) {
    final level = (profile.totalWins / 10).floor() + 1; // Calculate level from wins
    
    switch (achievementId) {
      case 'first_win':
        return profile.totalWins > 0;
      case 'win_streak_5':
        return profile.bestStreak >= 5;
      case 'win_streak_10':
        return profile.bestStreak >= 10;
      case 'games_100':
        return (profile.totalWins + profile.totalLosses + profile.totalDraws) >= 100;
      case 'games_500':
        return (profile.totalWins + profile.totalLosses + profile.totalDraws) >= 500;
      case 'level_10':
        return level >= 10;
      case 'level_50':
        return level >= 50;
      case 'pro_member':
        return profile.isPro;
      case 'coins_1000':
        return profile.coins >= 1000;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final unlockedCount = _achievements.where((a) => a.isUnlocked).length;
    final totalCount = _achievements.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('🏆 Arritjet'),
        backgroundColor: const Color(0xFF667eea),
      ),
      body: Column(
        children: [
          // Progress header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF667eea),
                  const Color(0xFF764ba2),
                ],
              ),
            ),
            child: Column(
              children: [
                Text(
                  '$unlockedCount / $totalCount',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Arritje të hapura',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: totalCount > 0 ? unlockedCount / totalCount : 0,
                  backgroundColor: Colors.white30,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 8,
                ),
              ],
            ),
          ),
          
          // Achievements list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadAchievements,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _achievements.length,
                      itemBuilder: (context, index) {
                        return _buildAchievementCard(_achievements[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(Achievement achievement) {
    final isLocked = !achievement.isUnlocked;
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      elevation: isLocked ? 1 : 4,
      color: isLocked ? Colors.grey[200] : Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: isLocked ? Colors.grey[300] : const Color(0xFF667eea),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              isLocked ? '🔒' : achievement.icon,
              style: const TextStyle(fontSize: 32),
            ),
          ),
        ),
        title: Text(
          achievement.title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isLocked ? Colors.grey[600] : Colors.black,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              achievement.description,
              style: TextStyle(
                fontSize: 14,
                color: isLocked ? Colors.grey[500] : Colors.grey[700],
              ),
            ),
            if (isLocked) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: _getAchievementProgress(achievement),
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
              ),
              const SizedBox(height: 4),
              Text(
                _getProgressText(achievement),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ] else ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'E hapur',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: isLocked
            ? null
            : Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.star, color: Colors.white),
              ),
      ),
    );
  }

  double _getAchievementProgress(Achievement achievement) {
    final profile = Provider.of<UserProfile>(context, listen: false);
    final level = (profile.totalWins / 10).floor() + 1; // Calculate level
    
    switch (achievement.id) {
      case 'first_win':
        return profile.totalWins > 0 ? 1.0 : 0.0;
      case 'win_streak_5':
        return (profile.bestStreak / 5).clamp(0.0, 1.0);
      case 'win_streak_10':
        return (profile.bestStreak / 10).clamp(0.0, 1.0);
      case 'games_100':
        final total = profile.totalWins + profile.totalLosses + profile.totalDraws;
        return (total / 100).clamp(0.0, 1.0);
      case 'games_500':
        final total = profile.totalWins + profile.totalLosses + profile.totalDraws;
        return (total / 500).clamp(0.0, 1.0);
      case 'level_10':
        return (level / 10).clamp(0.0, 1.0);
      case 'level_50':
        return (level / 50).clamp(0.0, 1.0);
      case 'pro_member':
        return profile.isPro ? 1.0 : 0.0;
      case 'coins_1000':
        return (profile.coins / 1000).clamp(0.0, 1.0);
      default:
        return 0.0;
    }
  }

  String _getProgressText(Achievement achievement) {
    final profile = Provider.of<UserProfile>(context, listen: false);
    final level = (profile.totalWins / 10).floor() + 1; // Calculate level
    
    switch (achievement.id) {
      case 'first_win':
        return '${profile.totalWins} / 1 fitore';
      case 'win_streak_5':
        return '${profile.bestStreak} / 5 fitore në seri';
      case 'win_streak_10':
        return '${profile.bestStreak} / 10 fitore në seri';
      case 'games_100':
        final total = profile.totalWins + profile.totalLosses + profile.totalDraws;
        return '$total / 100 lojëra';
      case 'games_500':
        final total = profile.totalWins + profile.totalLosses + profile.totalDraws;
        return '$total / 500 lojëra';
      case 'level_10':
        return 'Niveli $level / 10';
      case 'level_50':
        return 'Niveli $level / 50';
      case 'pro_member':
        return profile.isPro ? 'E hapur' : 'Bli PRO për të hapur';
      case 'coins_1000':
        return '${profile.coins} / 1000 monedha';
      default:
        return '';
    }
  }
}
