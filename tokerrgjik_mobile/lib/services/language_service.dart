import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'translations.dart';

class LanguageService extends ChangeNotifier {
  static const String _languageKey = 'app_language';
  String _currentLanguage = 'sq'; // Default Albanian

  String get currentLanguage => _currentLanguage;

  LanguageService() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString(_languageKey) ?? 'sq';
    // Sync with Translations class
    await Translations.setLanguage(_currentLanguage);
    notifyListeners();
  }

  Future<void> setLanguage(String languageCode) async {
    if (_currentLanguage == languageCode) return;
    
    _currentLanguage = languageCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);
    
    // CRITICAL: Sync with the Translations class
    await Translations.setLanguage(languageCode);
    
    notifyListeners();
  }

  String translate(String key) {
    return _translations[_currentLanguage]?[key] ?? key;
  }

  // Translation map
  static const Map<String, Map<String, String>> _translations = {
    'sq': {
      // Navigation
      'home': 'Ballina',
      'play': 'Luaj',
      'statistics': 'Statistika',
      'leaderboard': 'Klasifikimi',
      'shop': 'Dyqani',
      'friends': 'Miqtë',
      'settings': 'Cilësimet',
      
      // Game modes
      'single_player': 'Lojtar i vetëm',
      'multiplayer': 'Shumë lojtarë',
      'practice': 'Praktikë',
      'ranked': 'Me renditje',
      'vs_ai': 'Luaj kundër AI',
      'local_multiplayer': 'Luaj me mik (Lokal)',
      'online': 'Luaj online',
      'rules': 'Rregullat',
      
      // Common actions
      'login': 'Hyr',
      'register': 'Regjistrohu',
      'logout': 'Dil',
      'save': 'Ruaj',
      'cancel': 'Anulo',
      'ok': 'OK',
      'yes': 'Po',
      'no': 'Jo',
      'back': 'Kthehu',
      'next': 'Vazhdo',
      'start': 'Fillo',
      'finish': 'Përfundo',
      'buy': 'Bli',
      'confirm': 'Konfirmo',
      
      // User profile
      'username': 'Emri i përdoruesit',
      'email': 'Email',
      'password': 'Fjalëkalimi',
      'profile': 'Profili',
      'level': 'Niveli',
      'coins': 'Monedha',
      'wins': 'Fitore',
      'losses': 'Humbje',
      'draws': 'Barazime',
      'total_games': 'Lojëra totale',
      'win_rate': 'Norma e fitores',
      
      // Shop
      'shop_title': 'Dyqani',
      'coins_packs': 'Pako Monedhash',
      'pro_packages': 'Pako PRO',
      'purchase': 'Bli',
      'free': 'Falas',
      
      // Settings
      'settings_title': 'Cilësimet',
      'language': 'Gjuha',
      'sound': 'Tingujt',
      'music': 'Muzika',
      'notifications': 'Njoftimet',
      'theme': 'Tema',
      'dark_mode': 'Mënyra e errët',
      'light_mode': 'Mënyra e ndritshme',
      
      // Game
      'your_turn': 'Radha jote',
      'opponent_turn': 'Radha e kundërshtarit',
      'you_won': 'Ti fitove!',
      'you_lost': 'Ti humbe!',
      'draw': 'Barazim!',
      'waiting_for_opponent': 'Duke pritur kundërshtarin...',
      'game_over': 'Loja përfundoi',
      'play_again': 'Luaj përsëri',
      
      // Leaderboard
      'leaderboard_title': 'Klasifikimi',
      'rank': 'Vendi',
      'player': 'Lojtar',
      'score': 'Pikët',
      'global': 'Global',
      'friends_only': 'Vetëm miqtë',
      
      // Developer info
      'developer_info': 'Rreth aplikacionit',
      'about_app': 'Ç\'është TokerrGjik?',
      'developer': 'Zhvilluar nga',
      'version': 'Versioni',
      'contact': 'Kontakti',
      
      // Errors
      'error': 'Gabim',
      'success': 'Sukses',
      'loading': 'Duke ngarkuar...',
      'no_internet': 'Nuk ka internet',
      'try_again': 'Provo përsëri',
      'invalid_credentials': 'Kredenciale të gabuara',
      'username_taken': 'Emri i përdoruesit është i zënë',
      'email_taken': 'Email-i është i zënë',
      'passwords_dont_match': 'Fjalëkalimet nuk përputhen',
      
      // Payment
      'payment_success': 'Pagesa u krye me sukses!',
      'payment_cancelled': 'Pagesa u anulua',
      'payment_failed': 'Pagesa dështoi',
      'processing_payment': 'Duke procesuar pagesën...',
      'i_have_paid': 'Kam paguar',
    },
    'en': {
      // Navigation
      'home': 'Home',
      'play': 'Play',
      'statistics': 'Statistics',
      'leaderboard': 'Leaderboard',
      'shop': 'Shop',
      'friends': 'Friends',
      'settings': 'Settings',
      
      // Game modes
      'single_player': 'Single Player',
      'multiplayer': 'Multiplayer',
      'practice': 'Practice',
      'ranked': 'Ranked',
      'vs_ai': 'Play against AI',
      'local_multiplayer': 'Play with friend (Local)',
      'online': 'Play online',
      'rules': 'Rules',
      
      // Common actions
      'login': 'Login',
      'register': 'Register',
      'logout': 'Logout',
      'save': 'Save',
      'cancel': 'Cancel',
      'ok': 'OK',
      'yes': 'Yes',
      'no': 'No',
      'back': 'Back',
      'next': 'Next',
      'start': 'Start',
      'finish': 'Finish',
      'buy': 'Buy',
      'confirm': 'Confirm',
      
      // User profile
      'username': 'Username',
      'email': 'Email',
      'password': 'Password',
      'profile': 'Profile',
      'level': 'Level',
      'coins': 'Coins',
      'wins': 'Wins',
      'losses': 'Losses',
      'draws': 'Draws',
      'total_games': 'Total Games',
      'win_rate': 'Win Rate',
      
      // Shop
      'shop_title': 'Shop',
      'coins_packs': 'Coin Packs',
      'pro_packages': 'PRO Packages',
      'purchase': 'Purchase',
      'free': 'Free',
      
      // Settings
      'settings_title': 'Settings',
      'language': 'Language',
      'sound': 'Sound',
      'music': 'Music',
      'notifications': 'Notifications',
      'theme': 'Theme',
      'dark_mode': 'Dark Mode',
      'light_mode': 'Light Mode',
      
      // Game
      'your_turn': 'Your turn',
      'opponent_turn': 'Opponent\'s turn',
      'you_won': 'You won!',
      'you_lost': 'You lost!',
      'draw': 'Draw!',
      'waiting_for_opponent': 'Waiting for opponent...',
      'game_over': 'Game Over',
      'play_again': 'Play Again',
      
      // Leaderboard
      'leaderboard_title': 'Leaderboard',
      'rank': 'Rank',
      'player': 'Player',
      'score': 'Score',
      'global': 'Global',
      'friends_only': 'Friends Only',
      
      // Developer info
      'developer_info': 'About App',
      'about_app': 'What is TokerrGjik?',
      'developer': 'Developed by',
      'version': 'Version',
      'contact': 'Contact',
      
      // Errors
      'error': 'Error',
      'success': 'Success',
      'loading': 'Loading...',
      'no_internet': 'No internet connection',
      'try_again': 'Try again',
      'invalid_credentials': 'Invalid credentials',
      'username_taken': 'Username is taken',
      'email_taken': 'Email is taken',
      'passwords_dont_match': 'Passwords don\'t match',
      
      // Payment
      'payment_success': 'Payment successful!',
      'payment_cancelled': 'Payment cancelled',
      'payment_failed': 'Payment failed',
      'processing_payment': 'Processing payment...',
      'i_have_paid': 'I have paid',
    },
  };
}
