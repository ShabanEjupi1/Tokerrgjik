import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tokerrgjik_mobile/models/game_state.dart';
import 'package:tokerrgjik_mobile/models/user_profile.dart';
import 'package:tokerrgjik_mobile/services/ad_service.dart';
import 'package:tokerrgjik_mobile/services/sound_service.dart';
import 'package:tokerrgjik_mobile/services/storage_service.dart';
import 'package:tokerrgjik_mobile/services/database_service.dart';
import 'package:tokerrgjik_mobile/services/chat_service.dart';
import 'package:tokerrgjik_mobile/services/sentry_service.dart';
import 'package:tokerrgjik_mobile/services/notification_service.dart';
import 'package:tokerrgjik_mobile/services/auth_service.dart';
import 'package:tokerrgjik_mobile/services/local_storage_service.dart';
import 'package:tokerrgjik_mobile/services/language_service.dart';
import 'package:tokerrgjik_mobile/services/translations.dart';
import 'package:tokerrgjik_mobile/services/cryptolens_service.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/shop_screen.dart';
import 'screens/leaderboard_screen.dart';
import 'screens/friends_screen.dart';
import 'screens/statistics_screen.dart';
import 'screens/achievements_screen.dart';

void main() async {
  // Initialize Sentry first to catch all errors
  await SentryService.initialize();
  
  // Run app with Sentry error handling
  await SentryService.measurePerformance(
    name: 'app-initialization',
    operation: 'init',
    function: () async {
      WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  try {
    // Initialize SharedPreferences storage
    await StorageService.initialize();
    print('Storage service initialized successfully');
  } catch (e) {
    print('Storage initialization error: $e');
  }
  
  try {
    // Initialize SQLite database for persistent storage
    await DatabaseService.initialize();
    print('Database service initialized successfully');
  } catch (e) {
    print('Database initialization error: $e');
  }
  
  try {
    // Initialize AdMob
    await AdService.initialize();
    print('Ad service initialized successfully');
  } catch (e) {
    print('Ad initialization error: $e');
  }
  
  try {
    // Initialize notifications for player turn alerts
    await NotificationService.initialize();
    print('Notification service initialized successfully');
  } catch (e) {
    print('Notification initialization error: $e');
  }
  
  try {
    // Initialize LocalStorageService for mobile
    await LocalStorageService().init();
    print('Local storage initialized successfully');
  } catch (e) {
    print('Local storage initialization error: $e');
  }
  
  try {
    // Initialize Translations (language support)
    await Translations.loadLanguage();
    print('Translations loaded: ${Translations.currentLanguage}');
  } catch (e) {
    print('Translations initialization error: $e');
  }
  
  try {
    // Initialize Cryptolens License Protection
    await CryptolensService.initialize();
    print('License protection initialized');
    print('Licensed: ${CryptolensService.isLicensed}');
  } catch (e) {
    print('License initialization error: $e');
  }
  
  try {
    // Initialize AuthService and check login status
    await AuthService.initialize();
    print('Auth service initialized successfully');
    print('User logged in: ${AuthService.isLoggedIn}');
    print('Current username: ${AuthService.currentUsername}');
  } catch (e) {
    print('Auth initialization error: $e');
  }
  
      // Initialize sound service
      SoundService.initialize();
      
      // Lock to portrait mode for better gameplay
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      
      // Set status bar color
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      );
      
      runApp(const TokerrgjikApp());
    },
  );
}

class TokerrgjikApp extends StatelessWidget {
  const TokerrgjikApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => GameState()),
        ChangeNotifierProvider(
          create: (context) => UserProfile()..loadProfile(),
        ),
        ChangeNotifierProvider(create: (context) => LanguageService()),
        // Chat service - will be initialized when needed with actual user ID
        ChangeNotifierProvider(
          create: (context) => ChatService(
            currentUserId: 'user_${DateTime.now().millisecondsSinceEpoch}',
            currentUserName: 'Player',
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Tokerrgjik',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        // Check if user is logged in, show LoginScreen if not
        home: AuthService.isLoggedIn && !AuthService.isGuest 
            ? const HomeScreen() 
            : const LoginScreen(),
        routes: {
          '/home': (context) => const HomeScreen(),
          '/login': (context) => const LoginScreen(),
          '/settings': (context) => const SettingsScreen(),
          '/shop': (context) => const ShopScreen(),
          '/leaderboard': (context) => const LeaderboardScreen(),
          '/friends': (context) => const FriendsScreen(),
          '/statistics': (context) => const StatisticsScreen(),
          '/achievements': (context) => const AchievementsScreen(),
        },
      ),
    );
  }
}
