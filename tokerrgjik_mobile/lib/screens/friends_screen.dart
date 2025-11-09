import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/user_profile.dart';
import '../services/sound_service.dart';
import '../services/friends_service.dart';
import '../services/auth_service.dart';

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
    
    // Load friend requests when screen opens
    _loadFriendRequests();
    
    // Auto-refresh friend requests every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _loadFriendRequests();
      }
    });
  }
  
  Future<void> _loadFriendRequests() async {
    final currentUsername = AuthService.currentUsername;
    if (currentUsername == null) return;
    
    // Load pending requests from API
    final pendingRequests = await FriendsService.getPendingRequests(currentUsername);
    
    if (mounted) {
      final profile = Provider.of<UserProfile>(context, listen: false);
      // Update the profile with pending requests
      for (var request in pendingRequests) {
        final fromUsername = request['from_username'] ?? request['user_username'];
        if (fromUsername != null && !profile.friendRequests.contains(fromUsername)) {
          profile.friendRequests.add(fromUsername);
        }
      }
      setState(() {});
    }
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
              onPressed: () async {
                final username = controller.text.trim();
                if (username.isNotEmpty) {
                  final currentUsername = AuthService.currentUsername;
                  if (currentUsername == null) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Duhet të hysh në llogari')),
                    );
                    return;
                  }

                  // Send friend request via API
                  final result = await FriendsService.sendFriendRequest(
                    fromUsername: currentUsername,
                    toUsername: username,
                  );

                  SoundService.playClick();
                  Navigator.pop(context);

                  if (result != null && result['success'] == true) {
                    // Also update local profile
                    final profile = Provider.of<UserProfile>(context, listen: false);
                    profile.sendFriendRequest(username);

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('✅ Kërkesa u dërgua tek $username')),
                      );
                      setState(() {}); // Refresh UI
                    }
                  } else {
                    if (mounted) {
                      final errorMsg = result?['error'] ?? 'Nuk u dërgua';
                      final status = result?['status'];
                      
                      // Check if it's a duplicate request error
                      if (errorMsg.contains('already exists') || errorMsg.contains('Friend request already exists')) {
                        if (status == 'pending') {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('ℹ️ Kërkesa është dërguar tashmë tek $username. Prit përgjigjen.'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        } else if (status == 'accepted') {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('✅ Ju jeni tashmë miq me $username!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('ℹ️ Lidhje ekzistuese me $username (Status: ${status ?? 'unknown'})'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('❌ Gabim: $errorMsg')),
                        );
                      }
                    }
                  }
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

  void _removeFriend(BuildContext context, UserProfile profile, String friend) async {
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
              onPressed: () async {
                final currentUsername = AuthService.currentUsername;
                if (currentUsername == null) {
                  Navigator.pop(context);
                  return;
                }

                // Remove friend via API
                final success = await FriendsService.removeFriend(
                  username: currentUsername,
                  friendUsername: friend,
                );

                SoundService.playClick();
                Navigator.pop(context);

                if (success) {
                  // Also update local profile
                  profile.removeFriend(friend);

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('✅ $friend u hoq nga miqtë')),
                    );
                    setState(() {}); // Refresh UI
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('❌ Gabim gjatë heqjes së mikut')),
                    );
                  }
                }
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
