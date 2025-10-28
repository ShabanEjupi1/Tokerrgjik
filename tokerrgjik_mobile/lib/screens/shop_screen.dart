import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/user_profile.dart';
import '../services/ad_service.dart';
import '../services/sound_service.dart';
import '../services/paypal_service.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';
import '../services/auth_service.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    AdService.loadRewardedAd();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dyqani'),
        backgroundColor: const Color(0xFF667eea),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.diamond), text: 'PRO'),
            Tab(icon: Icon(Icons.palette), text: 'Themes'),
            Tab(icon: Icon(Icons.monetization_on), text: 'Monedha'),
            Tab(icon: Icon(Icons.video_library), text: 'Reklama'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProTab(),
          _buildThemesTab(),
          _buildCoinsTab(),
          _buildAdsTab(),
        ],
      ),
    );
  }

  Widget _buildProTab() {
    return Consumer<UserProfile>(
      builder: (context, profile, child) {
        if (profile.isPro) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, size: 100, color: Colors.green),
                const SizedBox(height: 20),
                const Text(
                  '✨ Ti je PRO! ✨',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  'Faleminderit për mbështetjen!',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildProCard(
              title: 'TOKERRGJIK PRO',
              subtitle: '12 muaj',
              price: '€20.82',
              originalPrice: '€41.64',
              discount: '50% ZBRITJE!',
              features: const [
                '✓ Pa reklama për gjithmonë',
                '✓ Themes ekskluzive',
                '✓ Ikona dhe ngjyra të personalizuara',
                '✓ 1000 monedha bonus',
                '✓ Badge "PRO" në leaderboard',
                '✓ Mbështetje prioritare',
              ],
              onTap: () => _purchasePro(context, profile, 12, 20.82),
            ),
            const SizedBox(height: 16),
            _buildProCard(
              title: 'TOKERRGJIK PRO',
              subtitle: '6 muaj',
              price: '€12.99',
              features: const [
                '✓ Pa reklama për 6 muaj',
                '✓ Themes ekskluzive',
                '✓ 500 monedha bonus',
                '✓ Badge "PRO" në leaderboard',
              ],
              onTap: () => _purchasePro(context, profile, 6, 12.99),
            ),
            const SizedBox(height: 16),
            _buildProCard(
              title: 'TOKERRGJIK PRO',
              subtitle: '1 muaj',
              price: '€2.99',
              features: const [
                '✓ Pa reklama për 1 muaj',
                '✓ Themes ekskluzive',
                '✓ 100 monedha bonus',
              ],
              onTap: () => _purchasePro(context, profile, 1, 2.99),
            ),
          ],
        );
      },
    );
  }

  Widget _buildThemesTab() {
    return Consumer<UserProfile>(
      builder: (context, profile, child) {
        final themes = [
          {'name': 'Klasike (Ari)', 'color': const Color(0xFFDAA520), 'cost': 0, 'id': 'classic', 'description': 'Tabelë e artë 3D me ngjyra klasike'},
          {'name': 'E errët', 'color': const Color(0xFF424242), 'cost': 0, 'id': 'dark', 'description': 'Tabelë e errët me figura të ndritshme'},
          {'name': 'Natyrore', 'color': const Color(0xFF8B4513), 'cost': 150, 'id': 'nature', 'description': 'Ngjyra druri natyror'},
          {'name': 'Oqean', 'color': const Color(0xFF1E90FF), 'cost': 200, 'id': 'ocean', 'description': 'Temë blu oqeani'},
          {'name': 'E personalizuar', 'color': const Color(0xFFDAA520), 'cost': 5000, 'id': 'custom', 'description': 'Krijuar nga ti - zgjedh ngjyrat'},
        ];

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [profile.boardColor, profile.boardColor.withOpacity(0.5)],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
              ),
              child: Column(
                children: [
                  const Text(
                    '🎨 Tema aktuale',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.monetization_on, color: Colors.amber, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        '${profile.coins} monedha',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ...themes.map((theme) => _buildThemeCard(context, profile, theme)),
          ],
        );
      },
    );
  }

  Widget _buildThemeCard(BuildContext context, UserProfile profile, Map<String, dynamic> theme) {
    final String themeId = theme['id'] as String;
    final String themeName = theme['name'] as String;
    final Color themeColor = theme['color'] as Color;
    final int themeCost = theme['cost'] as int;
    
    final bool isUnlocked = themeCost == 0 || profile.unlockedThemes.contains(themeId) || (themeCost == -1 && profile.isPro);
    final bool isCurrent = profile.currentTheme == themeId;
    final bool isProOnly = themeCost == -1;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isCurrent ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isCurrent ? BorderSide(color: themeColor, width: 3) : BorderSide.none,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: themeColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: themeColor.withOpacity(0.5),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: isCurrent
              ? const Icon(Icons.check, color: Colors.white, size: 32)
              : null,
        ),
        title: Text(
          themeName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: isProOnly
            ? const Row(
                children: [
                  Icon(Icons.diamond, size: 16, color: Colors.amber),
                  SizedBox(width: 4),
                  Text('Vetëm për PRO', style: TextStyle(color: Colors.orange)),
                ],
              )
            : isUnlocked
                ? (isCurrent
                    ? const Text('✨ Aktiv', style: TextStyle(color: Colors.green))
                    : const Text('✓ E zhbllokuar', style: TextStyle(color: Colors.blue)))
                : Row(
                    children: [
                      const Icon(Icons.lock, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('$themeCost monedha', style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
        trailing: isUnlocked
            ? (isCurrent
                ? const Icon(Icons.check_circle, color: Colors.green, size: 32)
                : TextButton(
                    onPressed: () => _selectTheme(context, profile, themeId, themeColor),
                    child: const Text('Zgjidh'),
                  ))
            : ElevatedButton.icon(
                onPressed: profile.coins >= themeCost
                    ? () => _unlockTheme(context, profile, themeId, themeName, themeCost, themeColor)
                    : null,
                icon: const Icon(Icons.shopping_cart, size: 16),
                label: Text('$themeCost'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey,
                ),
              ),
      ),
    );
  }

  void _selectTheme(BuildContext context, UserProfile profile, String themeId, Color color) {
    setState(() {
      profile.setTheme(themeId, color);
      LocalStorageService().saveUser({
        ...profile.toJson(),
        'currentTheme': themeId,
        'boardColor': color.value.toString(),
      });
    });
    SoundService.playClick();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✨ Tema u aktivizua!'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _unlockTheme(BuildContext context, UserProfile profile, String themeId, String themeName, int cost, Color color) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Zhblloko Temën'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.5),
                    blurRadius: 16,
                    spreadRadius: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              themeName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.monetization_on, color: Color(0xFFDAA520)),
                const SizedBox(width: 8),
                Text(
                  '$cost monedha',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Monedha aktuale: ${profile.coins}',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Anulo'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
            ),
            child: const Text('Zhblloko'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      if (profile.spendCoins(cost)) {
        profile.unlockTheme(themeId);
        await LocalStorageService().unlockTheme(themeId);
        await LocalStorageService().saveUser(profile.toJson());
        
        SoundService.playCoin();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🎉 $themeName u zhbllokua!'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Auto-select the newly unlocked theme
          _selectTheme(context, profile, themeId, color);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Monedha të pamjaftueshme!'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildCoinsTab() {
    return Consumer<UserProfile>(
      builder: (context, profile, child) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildCoinBalance(profile.coins),
            const SizedBox(height: 24),
            _buildCoinPackage(
              context,
              profile,
              coins: 10000,
              price: '€20.82',
              originalPrice: '€41.64',
              discount: '50% ZBRITJE!',
              icon: '💎',
            ),
            const SizedBox(height: 16),
            _buildCoinPackage(
              context,
              profile,
              coins: 5000,
              price: '€12.99',
              icon: '💰',
            ),
            const SizedBox(height: 16),
            _buildCoinPackage(
              context,
              profile,
              coins: 2000,
              price: '€5.99',
              icon: '🪙',
            ),
            const SizedBox(height: 16),
            _buildCoinPackage(
              context,
              profile,
              coins: 500,
              price: '€1.99',
              icon: '🔹',
            ),
            const SizedBox(height: 24),
            _buildInfoCard(
              'Përdor monedhat për:',
              [
                '• Blerje e themes dhe ikonave',
                '• Unlock karaktere speciale',
                '• Skip reklamave (nëse nuk je PRO)',
                '• Merr hint gjatë lojës',
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildAdsTab() {
    return Consumer<UserProfile>(
      builder: (context, profile, child) {
        if (profile.isPro) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.block, size: 100, color: Colors.orange),
                const SizedBox(height: 20),
                const Text(
                  'Pa reklama!',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  'Ti je PRO - nuk do të shohësh reklama',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Ad-skip with coins (temporary)
            if (!profile.isAdFree)
              Card(
                color: Colors.orange.shade50,
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Icon(Icons.block, size: 80, color: Colors.orange),
                      const SizedBox(height: 16),
                      const Text(
                        'Skip reklamat për 24 orë',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Bëhu pa reklama për 24 orë duke përdorur monedha!',
                        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: profile.coins >= 5000
                            ? () => _skipAdsWithCoins(context, profile, 24, 5000)
                            : null,
                        icon: const Icon(Icons.monetization_on, size: 24, color: Color(0xFFDAA520)),
                        label: const Text(
                          '5000 monedha - 24 orë',
                          style: TextStyle(fontSize: 18),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Monedhat e tua: ${profile.coins}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
            if (!profile.isAdFree) const SizedBox(height: 16),
            
            // Show current ad-free status if active
            if (profile.isAdFree && !profile.isPro)
              Card(
                color: Colors.green.shade50,
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Icon(Icons.check_circle, size: 80, color: Colors.green),
                      const SizedBox(height: 16),
                      const Text(
                        '✨ Pa reklama aktiv!',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Nuk do të shohësh reklama deri më ${_formatDateTime(profile.adFreeUntil!)}',
                        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            if (profile.isAdFree && !profile.isPro) const SizedBox(height: 16),
            
            // Watch ad for coins
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(Icons.play_circle_outline, size: 80, color: Color(0xFF667eea)),
                    const SizedBox(height: 16),
                    const Text(
                      'Shiko reklamë - Merr monedha!',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Shiko një reklamë të shkurtër dhe merr 3 monedha falas!',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: AdService.isRewardedAdReady
                          ? () => _watchAdForCoins(context, profile)
                          : null,
                      icon: const Icon(Icons.play_arrow, size: 28),
                      label: Text(
                        AdService.isRewardedAdReady
                            ? 'Shiko reklamë'
                            : 'Duke u ngarkuar...',
                        style: const TextStyle(fontSize: 18),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF667eea),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildInfoCard(
              'Përfitime të reklamave:',
              [
                '• Merr 3 monedha për çdo reklamë',
                '• Reklamat janë 15-30 sekonda',
                '• Pa limit ditor!',
                '• Mbështet zhvilluesin e lojës',
              ],
            ),
            const SizedBox(height: 16),
            Card(
              color: Colors.orange[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.orange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Nuk do të shohësh reklama? Kalo në PRO!',
                        style: TextStyle(color: Colors.orange[900]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCoinBalance(int coins) {
    return Card(
      color: const Color(0xFFFFF9C4),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.monetization_on, size: 40, color: Colors.amber),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Monedhat e tua',
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                Text(
                  '$coins 🪙',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProCard({
    required String title,
    required String subtitle,
    required String price,
    String? originalPrice,
    String? discount,
    required List<String> features,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF667eea),
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  if (discount != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        discount,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              ...features.map((feature) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  feature,
                  style: const TextStyle(fontSize: 15),
                ),
              )),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (originalPrice != null)
                        Text(
                          originalPrice,
                          style: const TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      Text(
                        price,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF667eea),
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF667eea),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text('Bli tani', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoinPackage(
    BuildContext context,
    UserProfile profile, {
    required int coins,
    required String price,
    String? originalPrice,
    String? discount,
    required String icon,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _purchaseCoins(context, profile, coins, price),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 50)),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$coins Monedha',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (discount != null)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          discount,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (originalPrice != null)
                    Text(
                      originalPrice,
                      style: const TextStyle(
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  Text(
                    price,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF667eea),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, List<String> items) {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF667eea),
              ),
            ),
            const SizedBox(height: 12),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(item, style: const TextStyle(fontSize: 15)),
            )),
          ],
        ),
      ),
    );
  }

  void _purchasePro(BuildContext context, UserProfile profile, int months, double price) {
    // Start PayPal purchase flow and server-side verification
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // Create PayPal order on client then open approval URL
    PayPalService.createOrder(
      amount: price.toStringAsFixed(2),
      currency: 'EUR',
      description: 'TokerrGjik PRO - $months months',
    ).then((order) async {
      Navigator.pop(context);
      if (order == null || order['approval_url'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gabim me PayPal. Provoni përsëri.'), backgroundColor: Colors.red),
        );
        return;
      }

      // Open approval URL in browser
      final approvalUrl = Uri.parse(order['approval_url']);
      await PayPalService.purchaseProSubscription(context: context, months: months);

      // After user finishes in browser, client must verify with server
      // Here we open a dialog prompting the user to press "I've paid" which triggers server verification
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Përfundoni pagesën'),
            content: const Text('Pasi të keni përfunduar pagesën në PayPal, shtypni "Kam paguar" për të verifikuar.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Anulo')),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  // Verify payment with server
                  showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
                  final verification = await ApiService.post('/payments', {
                    'action': 'verify_payment',
                    'order_id': order['order_id'],
                    'username': AuthService.currentUsername ?? LocalStorageService().getUser()?['username'],
                    'package_id': months == 12 ? 'pro_yearly' : 'pro_monthly',
                  });
                  Navigator.pop(context);
                  if (verification != null && verification['success'] == true) {
                    profile.upgradeToPro();
                    profile.addCoins(months == 12 ? 1000 : months == 6 ? 500 : 100);
                    SoundService.playCoin();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(verification['message'] ?? 'Pro activated!'), backgroundColor: Colors.green),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Verifikimi i pagesës dështoi.'), backgroundColor: Colors.red),
                    );
                  }
                },
                child: const Text('Kam paguar'),
              ),
            ],
          );
        },
      );
    });
  }

  void _purchaseCoins(BuildContext context, UserProfile profile, int coins, String price) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Create PayPal order
      final order = await PayPalService.createOrder(
        amount: price.replaceAll('€', '').trim(),
        currency: 'EUR',
        description: 'TokerrGjik - $coins Monedha',
      );

      Navigator.pop(context); // Close loading

      if (order == null || order['approval_url'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Gabim me PayPal. Provoni përsëri.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Open PayPal in browser
      final approvalUrl = Uri.parse(order['approval_url']);
      if (await canLaunchUrl(approvalUrl)) {
        await launchUrl(approvalUrl, mode: LaunchMode.externalApplication);
        
        // Show verification dialog
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Përfundoni pagesën'),
              content: const Text('Pasi të keni përfunduar pagesën në PayPal, shtypni "Kam paguar" për të verifikuar.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Anulo'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    
                    // Show loading
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => const Center(child: CircularProgressIndicator()),
                    );
                    
                    // Verify payment with server
                    final verification = await ApiService.post('/payments', {
                      'action': 'verify_payment',
                      'order_id': order['order_id'],
                      'username': AuthService.currentUsername ?? profile.username,
                      'package_id': 'coins_$coins',
                    });
                    
                    Navigator.pop(context); // Close loading
                    
                    if (verification != null && verification['success'] == true) {
                      profile.addCoins(coins);
                      SoundService.playCoin();
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(verification['message'] ?? '🪙 Morët $coins monedha!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('❌ Verifikimi i pagesës dështoi. Kontaktoni suportin.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text('Kam paguar'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Gabim: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _watchAdForCoins(BuildContext context, UserProfile profile) {
    AdService.showRewardedAd((coins) {
      profile.addCoins(coins);
      SoundService.playCoin();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 Morët $coins monedha!'),
          backgroundColor: Colors.green,
        ),
      );
    });
  }
  
  void _skipAdsWithCoins(BuildContext context, UserProfile profile, int hours, int cost) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Skip reklamat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.block, size: 64, color: Colors.orange),
            const SizedBox(height: 16),
            Text(
              'Skip reklamat për $hours orë duke përdorur $cost monedha?',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Monedhat aktuale: ${profile.coins}',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anulo'),
          ),
          ElevatedButton(
            onPressed: () {
              if (profile.skipAdsWithCoins(hours, cost)) {
                SoundService.playCoin();
                Navigator.pop(context);
                setState(() {}); // Refresh UI
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✨ Pa reklama për $hours orë!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('❌ Monedha të pamjaftueshme!'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Konfirmo'),
          ),
        ],
      ),
    );
  }
  
  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
