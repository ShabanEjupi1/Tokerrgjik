import 'package:shared_preferences/shared_preferences.dart';

/// Translations service for multi-language support
/// Supports: Albanian (sq), English (en)
class Translations {
  static String _currentLanguage = 'sq'; // Default to Albanian
  
  static final Map<String, Map<String, String>> _translations = {
    // Game Actions
    'place_piece': {'sq': 'Vendos figurën', 'en': 'Place piece'},
    'move_piece': {'sq': 'Lëviz figurën', 'en': 'Move piece'},
    'remove_piece': {'sq': 'Hiq figurën', 'en': 'Remove piece'},
    'select_piece': {'sq': 'Zgjidh figurën për ta lëvizur', 'en': 'Select piece to move'},
    'select_destination': {'sq': 'Zgjidh ku ta lëvizësh', 'en': 'Select where to move'},
    
    // Game Phases
    'placing_phase': {'sq': 'Faza e vendosjes', 'en': 'Placing phase'},
    'moving_phase': {'sq': 'Faza e lëvizjes', 'en': 'Moving phase'},
    'removing_phase': {'sq': 'Faza e heqjes', 'en': 'Removing phase'},
    
    // Player Info
    'player': {'sq': 'Lojtari', 'en': 'Player'},
    'ai': {'sq': 'AI', 'en': 'AI'},
    'your_turn': {'sq': 'Radha jote', 'en': 'Your turn'},
    'opponent_turn': {'sq': 'Radha e kundërshtarit', 'en': "Opponent's turn"},
    
    // Game Results
    'you_won': {'sq': 'Ti fitove!', 'en': 'You won!'},
    'you_lost': {'sq': 'Ti humbe!', 'en': 'You lost!'},
    'draw': {'sq': 'Barazim!', 'en': 'Draw!'},
    'game_over': {'sq': 'Loja përfundoi', 'en': 'Game over'},
    
    // Hints
    'hint': {'sq': 'Hint Strategjik', 'en': 'Strategic Hint'},
    'buy_hint': {'sq': 'Blej Hint', 'en': 'Buy Hint'},
    'hint_cost': {'sq': 'monedha', 'en': 'coins'},
    'insufficient_coins': {'sq': 'Monedha të pamjaftueshme', 'en': 'Insufficient coins'},
    'no_hint_available': {'sq': 'Asnjë hint i disponueshëm për këtë situatë!', 'en': 'No hint available for this situation!'},
    'hint_purchased': {'sq': '✨ Hint i blerë!', 'en': '✨ Hint purchased!'},
    'play_more_games': {'sq': 'Luan më shumë lojëra ose bli monedha nga dyqani!', 'en': 'Play more games or buy coins from the shop!'},
    'go_to_shop': {'sq': 'Shko te Dyqani', 'en': 'Go to Shop'},
    
    // Hint Messages
    'hint_form_mill': {'sq': '💡 Vendose figurën në pozicionin {pos} për të formuar një rreth!', 'en': '💡 Place piece at position {pos} to form a mill!'},
    'hint_block_opponent': {'sq': '🛡️ Bllokoj kundërshtarin duke vendosur në pozicionin {pos}!', 'en': '🛡️ Block opponent by placing at position {pos}!'},
    'hint_strategic_pos': {'sq': '⭐ Pozicionet strategjike: {pos} janë më të mira!', 'en': '⭐ Strategic positions: {pos} are better!'},
    'hint_center_pieces': {'sq': '💭 Vendos figurat në qendër për fleksibilitet maksimal!', 'en': '💭 Place pieces in center for maximum flexibility!'},
    'hint_move_to_mill': {'sq': '🎯 Lëviz figurën nga {from} në {to} për të formuar rreth!', 'en': '🎯 Move piece from {from} to {to} to form a mill!'},
    'hint_block_move': {'sq': '🛡️ Bllokoj lëvizjen e kundërshtarit duke lëvizur në {pos}!', 'en': '🛡️ Block opponent move by moving to {pos}!'},
    'hint_strategic_move': {'sq': '🤔 Kërko të formosh rrathë duke lëvizur figurat në pozicione strategjike!', 'en': '🤔 Try to form mills by moving pieces to strategic positions!'},
    'hint_remove_all_in_mills': {'sq': '⚠️ Të gjitha figurat e kundërshtarit janë në rrathë. Mund të heqësh çdo figurë!', 'en': '⚠️ All opponent pieces are in mills. You can remove any piece!'},
    'hint_remove_strategic': {'sq': '⭐ Hiq figurën nga {pos} për të shkatërruar një rreth të mundshëm!', 'en': '⭐ Remove piece from {pos} to destroy a potential mill!'},
    'hint_remove_piece': {'sq': '💡 Hiq figurën e kundërshtarit nga një pozicion strategjik!', 'en': '💡 Remove opponent piece from a strategic position!'},
    
    // Menu Items
    'play': {'sq': 'Luaj', 'en': 'Play'},
    'settings': {'sq': 'Cilësimet', 'en': 'Settings'},
    'rules': {'sq': 'Rregullat', 'en': 'Rules'},
    'shop': {'sq': 'Dyqani', 'en': 'Shop'},
    'leaderboard': {'sq': 'Renditja', 'en': 'Leaderboard'},
    'friends': {'sq': 'Miqtë', 'en': 'Friends'},
    'profile': {'sq': 'Profili', 'en': 'Profile'},
    'statistics': {'sq': 'Statistikat', 'en': 'Statistics'},
    'achievements': {'sq': 'Arritjet', 'en': 'Achievements'},
    
    // Game Modes
    'vs_ai': {'sq': 'Kundër AI', 'en': 'VS AI'},
    'local_multiplayer': {'sq': 'Shumëlojtarë Lokal', 'en': 'Local Multiplayer'},
    'online': {'sq': 'Online', 'en': 'Online'},
    
    // Difficulty
    'easy': {'sq': 'Lehtë', 'en': 'Easy'},
    'medium': {'sq': 'Mesatar', 'en': 'Medium'},
    'hard': {'sq': 'Vështirë', 'en': 'Hard'},
    'expert': {'sq': 'Ekspert', 'en': 'Expert'},
    
    // Rules
    'how_to_play': {'sq': 'Si të luash tokerrgjik', 'en': 'How to play tokerrgjik'},
    'objective': {'sq': 'Qëllimi', 'en': 'Objective'},
    'objective_text': {'sq': 'Formo "rrathë" (3 figura në radhë) për të hequr figurat e kundërshtarit.', 'en': 'Form "mills" (3 pieces in a row) to remove opponent\'s pieces.'},
    'phases': {'sq': 'Fazat', 'en': 'Phases'},
    'phases_text': {'sq': '1. Vendos 9 figurat\n2. Lëviz figurat\n3. Fluturim me 3 figura', 'en': '1. Place 9 pieces\n2. Move pieces\n3. Flying with 3 pieces'},
    'winning': {'sq': 'Fitimi', 'en': 'Winning'},
    'winning_text': {'sq': 'Zvogëlo kundërshtarin në 2 figura ose bllokoj lëvizjet.', 'en': 'Reduce opponent to 2 pieces or block all moves.'},
    'rules_detail_1': {'sq': '1. Vendosja: Vendos 9 figurat në pika boshe', 'en': '1. Placing: Place 9 pieces on empty points'},
    'rules_detail_2': {'sq': '2. Lëvizja: Lëviz figurat në pika boshe ngjitur', 'en': '2. Moving: Move pieces to adjacent empty points'},
    'rules_detail_3': {'sq': '3. Fluturimi: Me 3 figura, mund të fluturosh kudo', 'en': '3. Flying: With 3 pieces, you can jump anywhere'},
    'how_to_win': {'sq': 'Si të fitosh:', 'en': 'How to win:'},
    'win_condition_1': {'sq': '• Zvogëlo kundërshtarin në 2 figura', 'en': '• Reduce opponent to 2 pieces'},
    'win_condition_2': {'sq': '• Bllokoj të gjitha lëvizjet e tij', 'en': '• Block all their moves'},
    
    // Settings
    'sound': {'sq': 'Tinguj', 'en': 'Sound'},
    'sound_subtitle': {'sq': 'Tinguj për lëvizje dhe veprime', 'en': 'Sounds for moves and actions'},
    'music': {'sq': 'Muzikë', 'en': 'Music'},
    'vibration': {'sq': 'Dridhje', 'en': 'Vibration'},
    'language': {'sq': 'Gjuha', 'en': 'Language'},
    'theme': {'sq': 'Tema', 'en': 'Theme'},
    'default_theme': {'sq': 'Temë paravendosur', 'en': 'Default theme'},
    'board_customization': {'sq': 'Personalizimi i tabelës', 'en': 'Board customization'},
    'difficulty_level': {'sq': 'Niveli i vështirësisë', 'en': 'Difficulty level'},
    
    // Authentication
    'login': {'sq': 'Kyçu', 'en': 'Login'},
    'register': {'sq': 'Regjistrohu', 'en': 'Register'},
    'logout': {'sq': 'Dil', 'en': 'Logout'},
    'username': {'sq': 'Emri i përdoruesit', 'en': 'Username'},
    'password': {'sq': 'Fjalëkalimi', 'en': 'Password'},
    'email': {'sq': 'Email', 'en': 'Email'},
    'full_name': {'sq': 'Emri i plotë', 'en': 'Full name'},
    'please_enter_username': {'sq': 'Ju lutem vendosni emrin e përdoruesit', 'en': 'Please enter username'},
    'please_enter_name': {'sq': 'Ju lutem vendosni emrin', 'en': 'Please enter name'},
    'please_enter_fullname': {'sq': 'Ju lutem vendosni emrin e plotë', 'en': 'Please enter full name'},
    'please_enter_email': {'sq': 'Ju lutem vendosni email', 'en': 'Please enter email'},
    'please_enter_password': {'sq': 'Ju lutem vendosni fjalëkalimin', 'en': 'Please enter password'},
    
    // Common
    'cancel': {'sq': 'Anulo', 'en': 'Cancel'},
    'ok': {'sq': 'OK', 'en': 'OK'},
    'close': {'sq': 'Mbyll', 'en': 'Close'},
    'save': {'sq': 'Ruaj', 'en': 'Save'},
    'delete': {'sq': 'Fshi', 'en': 'Delete'},
    'edit': {'sq': 'Ndrysho', 'en': 'Edit'},
    'yes': {'sq': 'Po', 'en': 'Yes'},
    'no': {'sq': 'Jo', 'en': 'No'},
    'back': {'sq': 'Kthehu', 'en': 'Back'},
    'next': {'sq': 'Vazhdo', 'en': 'Next'},
    'coins': {'sq': 'Monedha', 'en': 'Coins'},
    
    // Stats
    'wins': {'sq': 'Fitore', 'en': 'Wins'},
    'losses': {'sq': 'Humbje', 'en': 'Losses'},
    'draws': {'sq': 'Barazime', 'en': 'Draws'},
    'win_streak': {'sq': 'Seri fitoresh', 'en': 'Win streak'},
    'best_streak': {'sq': 'Seria më e mirë', 'en': 'Best streak'},
    'total_games': {'sq': 'Lojëra totale', 'en': 'Total games'},
    
    // Notifications
    'ai_moves': {'sq': 'AI Lëvizjet', 'en': 'AI Moves'},
    'ai_moves_desc': {'sq': 'Njoftime për lëvizjet e AI', 'en': 'Notifications for AI moves'},
    
    // Game Screen
    'surrender': {'sq': 'Dorëzohu', 'en': 'Surrender'},
    'surrender_title': {'sq': 'Dorëzohesh?', 'en': 'Surrender?'},
    'player_will_win': {'sq': 'Lojtari {player} do të fitojë!', 'en': 'Player {player} will win!'},
    'new_game': {'sq': 'Lojë e re', 'en': 'New Game'},
    'human': {'sq': 'Njeri', 'en': 'Human'},
    'ai_won': {'sq': 'AI fitoi!', 'en': 'AI won!'},
    'ai_stronger': {'sq': 'AI ishte më i fortë këtë herë!\n\nProvoje përsëri dhe fito!', 'en': 'AI was stronger this time!\n\nTry again and win!'},
    'player_1_won': {'sq': 'Lojtari 1 fitoi!', 'en': 'Player 1 won!'},
    'player_2_won': {'sq': 'Lojtari 2 fitoi!', 'en': 'Player 2 won!'},
    'congratulations': {'sq': 'Urime për fitoren!', 'en': 'Congratulations on winning!'},
    'mills': {'sq': 'Mills', 'en': 'Mills'},
    'coins_won': {'sq': 'Monedha fituar', 'en': 'Coins won'},
    'shilevek_bonus': {'sq': 'Shilevek bonus! 🌟', 'en': 'Shilevek bonus! 🌟'},
    'total_coins_won': {'sq': 'Total monedha fituar', 'en': 'Total coins won'},
    
    // Multiplayer
    'multiplayer': {'sq': 'Shumëlojtarë', 'en': 'Multiplayer'},
    'refresh': {'sq': 'Rifresko', 'en': 'Refresh'},
    'create_game': {'sq': 'Krijo Lojë', 'en': 'Create Game'},
    'waiting': {'sq': 'Duke pritur', 'en': 'Waiting'},
    'active': {'sq': 'Aktiv', 'en': 'Active'},
    'finished': {'sq': 'Përfunduar', 'en': 'Finished'},
    'your_game': {'sq': 'Loja jote', 'en': 'Your Game'},
    'join': {'sq': 'Bashkohu', 'en': 'Join'},
    'status': {'sq': 'Statusi', 'en': 'Status'},
    'error': {'sq': 'Gabim', 'en': 'Error'},
    'no_sessions': {'sq': 'Nuk ka lojëra të disponueshme', 'en': 'No available games'},
    'creating_session': {'sq': 'Duke krijuar lojën...', 'en': 'Creating game...'},
    
    // Friends Screen
    'friends_title': {'sq': '👥 Miqtë', 'en': '👥 Friends'},
    'invite_friends': {'sq': 'Fto Miq', 'en': 'Invite Friends'},
    'online': {'sq': '● Online', 'en': '● Online'},
    'offline': {'sq': '● Offline', 'en': '● Offline'},
    'challenge': {'sq': 'Sfidoje', 'en': 'Challenge'},
    'message': {'sq': 'Mesazh', 'en': 'Message'},
    'remove': {'sq': 'Hiq', 'en': 'Remove'},
    'wants_to_be_friend': {'sq': 'Dëshiron të bëhet mik', 'en': 'Wants to be friends'},
    'accepted_request_from': {'sq': 'Pranove kërkesën nga {username}', 'en': 'Accepted request from {username}'},
    'rejected_request_from': {'sq': 'Refuzove kërkesën nga {username}', 'en': 'Rejected request from {username}'},
    'add_friend': {'sq': 'Shto mik', 'en': 'Add Friend'},
    'send_request': {'sq': 'Dërgo kërkesë', 'en': 'Send Request'},
    'must_login': {'sq': 'Duhet të hysh në llogari', 'en': 'Must login'},
    'request_sent_to': {'sq': '✅ Kërkesa u dërgua tek {username}', 'en': '✅ Request sent to {username}'},
    'error_sending': {'sq': '❌ Gabim: {error}', 'en': '❌ Error: {error}'},
    'not_sent': {'sq': 'Nuk u dërgua', 'en': 'Not sent'},
    'challenge_sent_to': {'sq': 'Sfidë u dërgua tek {friend}! Prit përgjigjen...', 'en': 'Challenge sent to {friend}! Wait for response...'},
    'chat_with': {'sq': 'Chat me {friend} do të hapet së shpejti...', 'en': 'Chat with {friend} will open soon...'},
    'remove_friend_title': {'sq': 'Hiq mik', 'en': 'Remove Friend'},
    'remove_friend_confirm': {'sq': 'Je i sigurt që dëshiron të heqësh {friend} nga miqtë?', 'en': 'Are you sure you want to remove {friend} from friends?'},
    'friend_removed': {'sq': '✅ {friend} u hoq nga miqtë', 'en': '✅ {friend} removed from friends'},
    'error_removing_friend': {'sq': '❌ Gabim gjatë heqjes së mikut', 'en': '❌ Error removing friend'},
    
    // Login Screen
    'continue_as_guest': {'sq': 'Vazhdo si vizitor', 'en': 'Continue as guest'},
    'or': {'sq': 'OSE', 'en': 'OR'},
    'registration_successful': {'sq': 'Regjistrimi u krye me sukses!', 'en': 'Registration successful!'},
    'operation_failed': {'sq': 'Operacioni dështoi', 'en': 'Operation failed'},
    
    // Developer Info
    'about_app': {'sq': 'Rreth aplikacionit', 'en': 'About App'},
    'technologies': {'sq': 'Teknologjitë', 'en': 'Technologies'},
  };
  
  /// Get current language
  static String get currentLanguage => _currentLanguage;
  
  /// Set language
  static Future<void> setLanguage(String languageCode) async {
    if (languageCode != 'sq' && languageCode != 'en') {
      languageCode = 'sq'; // Fallback to Albanian
    }
    _currentLanguage = languageCode;
    final prefs = await SharedPreferences.getInstance();
    // Use the same key as LanguageService for consistency
    await prefs.setString('app_language', languageCode);
  }
  
  /// Load saved language
  static Future<void> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    // Use the same key as LanguageService for consistency
    _currentLanguage = prefs.getString('app_language') ?? 'sq';
  }
  
  /// Get translation
  static String tr(String key, {Map<String, String>? params}) {
    String text = _translations[key]?[_currentLanguage] ?? _translations[key]?['sq'] ?? key;
    
    // Replace parameters
    if (params != null) {
      params.forEach((key, value) {
        text = text.replaceAll('{$key}', value);
      });
    }
    
    return text;
  }
  
  /// Check if language is English
  static bool get isEnglish => _currentLanguage == 'en';
  
  /// Check if language is Albanian
  static bool get isAlbanian => _currentLanguage == 'sq';
}
