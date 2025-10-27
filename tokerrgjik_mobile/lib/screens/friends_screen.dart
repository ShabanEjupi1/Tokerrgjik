import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/user_profile.dart';
import '../services/sound_service.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Auto-refresh friend requests every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        // Refresh the friends list from provider
        final profile = Provider.of<UserProfile>(context, listen: false);
        // Force rebuild to show new friend requests
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('👥 Miqtë'),
        backgroundColor: const Color(0xFF3498DB),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: _showAddFriendDialog,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareInvite,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'Miqtë'),
            Tab(icon: Icon(Icons.mail), text: 'Kërkesat'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFriendsList(),
          _buildRequestsList(),
        ],
      ),
    );
  }

  Widget _buildFriendsList() {
    return Consumer<UserProfile>(
      builder: (context, profile, child) {
        if (profile.friends.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.group_off, size: 100, color: Colors.grey),
                const SizedBox(height: 20),
                const Text(
                  'Ende nuk ke miq',
                  style: TextStyle(fontSize: 20, color: Colors.grey),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _shareInvite,
                  icon: const Icon(Icons.share),
                  label: const Text('Fto Miq'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3498DB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: profile.friends.length,
          padding: const EdgeInsets.all(8),
          itemBuilder: (context, index) {
            final friend = profile.friends[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF3498DB),
                  child: Text(
                    friend[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(
                  friend,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('● Online'),
                trailing: PopupMenuButton(
                  icon: const Icon(Icons.more_vert),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'challenge',
                      child: Row(
                        children: [
                          Icon(Icons.sports_esports, size: 20),
                          SizedBox(width: 8),
                          Text('Sfidoje'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'chat',
                      child: Row(
                        children: [
                          Icon(Icons.chat, size: 20),
                          SizedBox(width: 8),
                          Text('Mesazh'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'remove',
                      child: Row(
                        children: [
                          Icon(Icons.person_remove, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Hiq', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    switch (value) {
                      case 'challenge':
                        _challengeFriend(friend);
                        break;
                      case 'chat':
                        _openChat(friend);
                        break;
                      case 'remove':
                        _removeFriend(context, profile, friend);
                        break;
                    }
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRequestsList() {
    return Consumer<UserProfile>(
      builder: (context, profile, child) {
        if (profile.friendRequests.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.mail_outline, size: 100, color: Colors.grey),
                SizedBox(height: 20),
                Text(
                  'Nuk ka kërkesa të reja',
                  style: TextStyle(fontSize: 20, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: profile.friendRequests.length,
          padding: const EdgeInsets.all(8),
          itemBuilder: (context, index) {
            final request = profile.friendRequests[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.orange,
                  child: Text(
                    request[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(
                  request,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('Dëshiron të bëhet mik'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check_circle, color: Colors.green),
                      onPressed: () {
                        profile.acceptFriendRequest(request);
                        SoundService.playClick();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Pranove kërkesën nga $request')),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      onPressed: () {
                        profile.declineFriendRequest(request);
                        SoundService.playClick();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Refuzove kërkesën nga $request')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddFriendDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Shto mik'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Emri i përdoruesit',
              hintText: 'Shkruaj emrin...',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person_search),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Anulo'),
            ),
            ElevatedButton(
              onPressed: () {
                final username = controller.text.trim();
                if (username.isNotEmpty) {
                  final profile = Provider.of<UserProfile>(context, listen: false);
                  profile.sendFriendRequest(username);
                  SoundService.playClick();
                  Navigator.pop(context);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Kërkesa u dërgua tek $username')),
                  );
                }
              },
              child: const Text('Dërgo kërkesë'),
            ),
          ],
        );
      },
    );
  }

  void _shareInvite() {
    Share.share(
      'Eja të luajmë Tokerrgjik! 🎮\n\n'
      'Shkarkoje aplikacionin dhe më sfido:\n'
      'https://tokerrgjik.netlify.app\n\n'
      'Emri im: ${Provider.of<UserProfile>(context, listen: false).username}',
      subject: 'Fto për Tokerrgjik',
    );
    SoundService.playClick();
  }

  void _challengeFriend(String friend) {
    // In real implementation, this would send a challenge request
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sfidë u dërgua tek $friend! Prit përgjigjen...')),
    );
    SoundService.playClick();
  }

  void _openChat(String friend) {
    // Navigate to chat screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Chat me $friend do të hapet së shpejti...')),
    );
    SoundService.playClick();
  }

  void _removeFriend(BuildContext context, UserProfile profile, String friend) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hiq mik'),
          content: Text('Je i sigurt që dëshiron të heqësh $friend nga miqtë?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Anulo'),
            ),
            ElevatedButton(
              onPressed: () {
                profile.removeFriend(friend);
                SoundService.playClick();
                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$friend u hoq nga miqtë')),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Hiq'),
            ),
          ],
        );
      },
    );
  }
}
