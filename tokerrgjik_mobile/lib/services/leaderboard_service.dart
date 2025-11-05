import 'api_service.dart';

class LeaderboardEntry {
  final String username;
  final int wins;
  final int totalGames;
  final double winRate;
  final int winStreak;
  final int rank;
  final int? coins;
  final int? level;
  
  LeaderboardEntry({
    required this.username,
    required this.wins,
    required this.totalGames,
    required this.winRate,
    required this.winStreak,
    required this.rank,
    this.coins,
    this.level,
  });
  
  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    final totalWins = json['total_wins'] ?? json['wins'] ?? 0;
    final totalLosses = json['total_losses'] ?? json['losses'] ?? 0;
    final totalDraws = json['total_draws'] ?? json['draws'] ?? 0;
    final totalGames = totalWins + totalLosses + totalDraws;
    final winRate = totalGames > 0 ? (totalWins / totalGames * 100) : 0.0;
    
    return LeaderboardEntry(
      username: json['username'] ?? 'Player',
      wins: totalWins,
      totalGames: totalGames,
      winRate: double.parse(winRate.toStringAsFixed(1)),
      winStreak: json['current_win_streak'] ?? json['winStreak'] ?? 0,
      rank: json['rank'] ?? 0,
      coins: json['coins'],
      level: json['level'],
    );
  }
}

class LeaderboardService {
  static Future<List<LeaderboardEntry>> getLeaderboard({int limit = 100}) async {
    try {
      // Try to fetch from real API
      final data = await ApiService.getLeaderboard(limit: limit);
      
      if (data.isNotEmpty) {
        print('✅ Loaded ${data.length} players from database');
        return data.map((entry) => LeaderboardEntry.fromJson(entry)).toList();
      }
    } catch (e) {
      print('⚠️ Error fetching leaderboard: $e');
    }
    
    // Return empty list instead of dummy data to show the issue
    print('⚠️ No data from database - returning empty list');
    return [];
  }
  
  static Future<Map<String, dynamic>?> getUserRank(String username) async {
    try {
      final rank = await ApiService.getUserRank(username);
      if (rank != null) {
        return {
          'rank': rank,
          'username': username,
        };
      }
    } catch (e) {
      print('Error fetching user rank: $e');
    }
    return null;
  }
  
  static Future<void> updatePlayerStats(String username, Map<String, int> stats) async {
    try {
      await ApiService.updateUserStats(
        username: username,
        wins: stats['wins'],
        losses: stats['losses'],
        draws: stats['draws'],
        coins: stats['coins'],
      );
      print('✅ Stats updated for $username');
    } catch (e) {
      print('Error updating stats: $e');
    }
  }
}
