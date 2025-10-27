import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_profile.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'package:fl_chart/fl_chart.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({Key? key}) : super(key: key);

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _statistics;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final username = AuthService.currentUsername;
      if (username == null) {
        throw Exception('Not logged in');
      }

      final stats = await ApiService.getUserStatistics(username);
      
      if (mounted) {
        setState(() {
          _statistics = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 Statistika'),
        backgroundColor: const Color(0xFF3498DB),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStatistics,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Gabim: $_error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadStatistics,
              child: const Text('Provo përsëri'),
            ),
          ],
        ),
      );
    }

    if (_statistics == null) {
      return const Center(
        child: Text('Nuk ka statistika'),
      );
    }

    final profile = Provider.of<UserProfile>(context);
    final totalGames = profile.totalWins + profile.totalLosses + profile.totalDraws;
    final winRate = totalGames > 0 ? (profile.totalWins / totalGames * 100) : 0.0;
    final level = (profile.totalWins / 10).floor() + 1; // Calculate level from wins

    return RefreshIndicator(
      onRefresh: _loadStatistics,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Overview Card
          _buildOverviewCard(profile, totalGames, winRate, level),
          const SizedBox(height: 16),
          
          // Win/Loss/Draw Chart
          _buildWinLossChart(profile),
          const SizedBox(height: 16),
          
          // Game Stats
          _buildGameStatsCard(profile),
          const SizedBox(height: 16),
          
          // Achievements Preview
          _buildAchievementsCard(),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(UserProfile profile, int totalGames, double winRate, int level) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: const Color(0xFF3498DB),
              child: Text(
                '$level',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              profile.username,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Niveli $level',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem('🎮', 'Lojëra', totalGames.toString()),
                _buildStatItem('🏆', 'Fitore', profile.totalWins.toString()),
                _buildStatItem('📊', 'Win Rate', '${winRate.toStringAsFixed(1)}%'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String emoji, String label, String value) {
    return Column(
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 24),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildWinLossChart(UserProfile profile) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rezultatet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: profile.totalWins.toDouble(),
                      title: '${profile.totalWins}',
                      color: Colors.green,
                      radius: 100,
                      titleStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      value: profile.totalLosses.toDouble(),
                      title: '${profile.totalLosses}',
                      color: Colors.red,
                      radius: 100,
                      titleStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      value: profile.totalDraws.toDouble(),
                      title: '${profile.totalDraws}',
                      color: Colors.orange,
                      radius: 100,
                      titleStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLegendItem(Colors.green, 'Fitore', profile.totalWins),
                _buildLegendItem(Colors.red, 'Humbje', profile.totalLosses),
                _buildLegendItem(Colors.orange, 'Barazime', profile.totalDraws),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, int value) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text('$label: $value'),
      ],
    );
  }

  Widget _buildGameStatsCard(UserProfile profile) {
    final level = (profile.totalWins / 10).floor() + 1; // Calculate level
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detajet e lojës',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatRow('💰 Monedha', profile.coins.toString()),
            const Divider(),
            _buildStatRow('🏆 Fitore', profile.totalWins.toString()),
            const Divider(),
            _buildStatRow('❌ Humbje', profile.totalLosses.toString()),
            const Divider(),
            _buildStatRow('🤝 Barazime', profile.totalDraws.toString()),
            const Divider(),
            _buildStatRow('⭐ Niveli', level.toString()),
            const Divider(),
            _buildStatRow('🎯 Niveli i vështirësisë', _getDifficultyName(profile.difficulty)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3498DB),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Arritjet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/achievements');
                  },
                  child: const Text('Shiko të gjitha'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.emoji_events, color: Color(0xFF3498DB), size: 32),
              title: const Text('Shiko arritjet e tua'),
              subtitle: const Text('Hap arritje të reja duke luajtur'),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () {
                Navigator.pushNamed(context, '/achievements');
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getDifficultyName(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return 'E lehtë';
      case 'medium':
        return 'Mesatare';
      case 'hard':
        return 'E vështirë';
      case 'expert':
        return 'Ekspert';
      default:
        return difficulty;
    }
  }
}
