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
      'sounds': 'Tinguj',
      'sound_effects': 'Efektet e zërit',
      'sound_effects_subtitle': 'Tinguj për lëvizje dhe veprime',
      'vibration': 'Dridhje',
      'vibration_subtitle': 'Feedback haptik për veprime',
      'ai_difficulty': 'Nivelet e AI',
      'difficulty_easy': 'E lehtë',
      'difficulty_easy_subtitle': 'Perfekt për fillestarë - 3 monedha për fitore',
      'difficulty_medium': 'Mesatare',
      'difficulty_medium_subtitle': 'Sfidë e balancuar - 5 monedha për fitore',
      'difficulty_hard': 'E vështirë',
      'difficulty_hard_subtitle': 'Për lojtarë të përvojshëm - 8 monedha për fitore',
      'difficulty_expert': 'Ekspert',
      'difficulty_expert_subtitle': 'Sfida maksimale! - 12 monedha për fitore',
      'appearance': 'Pamja',
      'player1_color': 'Ngjyra e lojtarit 1',
      'player2_color': 'Ngjyra e lojtarit 2',
      'board_color': 'Ngjyra e tabelës',
      'color_change_cost': '100 Monedha për ndryshim',
      'preset_theme': 'Temë paravendosur',
      'current_theme': 'Aktuale: ',
      'account': 'Llogaria',
      'player_name': 'Emri i lojtarit',
      'pro_account': 'Llogari PRO',
      'upgrade_to_pro': 'Kalo në PRO',
      'pro_features': 'Pa reklama, Themes ekskluzive',
      'upgrade_benefits': 'Hiq reklamat dhe merr avantazhe',
      'logout_title': 'Dil nga llogaria',
      'logout_subtitle': 'Shkyçu nga llogaria aktuale',
      'information': 'Informacion',
      'app_version': 'Versioni i aplikacionit',
      'license_status': 'License Status',
      'licensed_protected': 'Licensed & Protected',
      'no_license_limited': 'No License - Limited Features',
      'support': 'Mbështetje',
      'choose_color': 'Zgjedh ngjyrën',
      'save_and_buy': 'Ruaj dhe Blej',
      'not_enough_coins': 'Nuk ke mjaftueshëm monedha! Nevojiten {cost} monedha.',
      'color_changed': 'Ngjyra u ndryshua! (-{cost} monedha)',
      'choose_theme': 'Zgjedh temën',
      'buy_for_coins': 'Blej për {cost} monedha',
      'buy_in_shop': 'Bleje në Dyqan',
      'theme_unlocked': 'Tema e personalizuar u hap! (-{cost} monedha)',
      'change_name': 'Ndrysho emrin',
      'new_name': 'Emri i ri',
      'enter_new_name': 'Shkruaj emrin e ri...',
      'name_cannot_be_empty': 'Emri nuk mund të jetë bosh!',
      'name_min_length': 'Emri duhet të jetë së paku 3 karaktere!',
      'name_changed': 'Emri u ndryshua në "{username}"!',
      'name_taken_or_error': 'Emri është i zënë ose gabim në server!',
      'license_information': 'License information',
      'status': 'Status',
      'active': 'Active',
      'inactive': 'Inactive',
      'license_key': 'License Key',
      'expires': 'Expires',
      'days_remaining': 'days',
      'activations': 'Activations',
      'app_version_short': 'App Version',
      'all_rights_reserved': '© 2025 Shaban Ejupi\nAll Rights Reserved',
      'protected_by_cryptolens': 'Protected by Cryptolens License System',
      'patent_pending': '⚖️ Patent Pending:\n• Dual-save architecture\n• AI algorithms\n• Multiplayer sync',
      'close': 'Close',
      'get_license': 'Get License',
      'logout_confirm': 'Dil nga llogaria?',
      'logout_confirm_message': 'A jeni i sigurt që dëshironi të dilni nga llogaria? Të gjitha të dhënat e pashpëtuara do të humbasin.',
      'logged_out': 'U shkëputët me sukses',
      'buy_custom_theme': 'Blej Temë të Personalizuar',
      'buy_custom_theme_message': 'Dëshiron të blesh temën e personalizuar për {cost} monedha?\n\nKjo do të të lejojë të zgjedhësh ngjyrat e tua të preferuara!',
      
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
      'sounds': 'Sounds',
      'sound_effects': 'Sound effects',
      'sound_effects_subtitle': 'Sounds for moves and actions',
      'vibration': 'Vibration',
      'vibration_subtitle': 'Haptic feedback for actions',
      'ai_difficulty': 'AI difficulty',
      'difficulty_easy': 'Easy',
      'difficulty_easy_subtitle': 'Perfect for beginners - 3 coins per win',
      'difficulty_medium': 'Medium',
      'difficulty_medium_subtitle': 'Balanced challenge - 5 coins per win',
      'difficulty_hard': 'Hard',
      'difficulty_hard_subtitle': 'For experienced players - 8 coins per win',
      'difficulty_expert': 'Expert',
      'difficulty_expert_subtitle': 'Maximum challenge! - 12 coins per win',
      'appearance': 'Appearance',
      'player1_color': 'Player 1 color',
      'player2_color': 'Player 2 color',
      'board_color': 'Board color',
      'color_change_cost': '100 coins to change',
      'preset_theme': 'Preset theme',
      'current_theme': 'Current: ',
      'account': 'Account',
      'player_name': 'Player name',
      'pro_account': 'PRO account',
      'upgrade_to_pro': 'Upgrade to PRO',
      'pro_features': 'No ads, Exclusive themes',
      'upgrade_benefits': 'Remove ads and get advantages',
      'logout_title': 'Logout',
      'logout_subtitle': 'Sign out of current account',
      'information': 'Information',
      'app_version': 'App version',
      'license_status': 'License status',
      'licensed_protected': 'Licensed & protected',
      'no_license_limited': 'No license - Limited features',
      'support': 'Support',
      'choose_color': 'Choose color',
      'save_and_buy': 'Save and buy',
      'not_enough_coins': 'Not enough coins! Need {cost} coins.',
      'color_changed': 'Color changed! (-{cost} coins)',
      'choose_theme': 'Choose theme',
      'buy_for_coins': 'Buy for {cost} coins',
      'buy_in_shop': 'Buy in shop',
      'theme_unlocked': 'Custom theme unlocked! (-{cost} coins)',
      'change_name': 'Change name',
      'new_name': 'New name',
      'enter_new_name': 'Enter new name...',
      'name_cannot_be_empty': 'Name cannot be empty!',
      'name_min_length': 'Name must be at least 3 characters!',
      'name_changed': 'Name changed to "{username}"!',
      'name_taken_or_error': 'Name is taken or server error!',
      'license_information': 'License information',
      'status': 'Status',
      'active': 'Active',
      'inactive': 'Inactive',
      'license_key': 'License key',
      'expires': 'Expires',
      'days_remaining': 'days',
      'activations': 'Activations',
      'app_version_short': 'App version',
      'all_rights_reserved': '© 2025 Shaban Ejupi\nAll rights reserved',
      'protected_by_cryptolens': 'Protected by Cryptolens license system',
      'patent_pending': '⚖️ Patent Pending:\n• Dual-save architecture\n• AI algorithms\n• Multiplayer sync',
      'close': 'Close',
      'get_license': 'Get license',
      'logout_confirm': 'Logout?',
      'logout_confirm_message': 'Are you sure you want to logout? All unsaved data will be lost.',
      'logged_out': 'Logged out successfully',
      'buy_custom_theme': 'Buy custom theme',
      'buy_custom_theme_message': 'Do you want to buy the custom theme for {cost} coins?\n\nThis will allow you to choose your preferred colors!',
      
      // Game
      'your_turn': 'Your turn',
      'opponent_turn': 'Opponent\'s turn',
      'you_won': 'You won!',
      'you_lost': 'You lost!',
      'draw': 'Draw!',
      'waiting_for_opponent': 'Waiting for opponent...',
      'game_over': 'Game over',
      'play_again': 'Play again',
      
      // Leaderboard
      'leaderboard_title': 'Leaderboard',
      'rank': 'Rank',
      'player': 'Player',
      'score': 'Score',
      'global': 'Global',
      'friends_only': 'Friends only',
      
      // Developer info
      'developer_info': 'About app',
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
