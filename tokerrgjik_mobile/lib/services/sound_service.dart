import 'package:audioplayers/audioplayers.dart';

class SoundService {
  static final AudioPlayer _effectPlayer = AudioPlayer();
  static final AudioPlayer _musicPlayer = AudioPlayer();
  
  static bool _soundEnabled = true;
  static bool _musicEnabled = true;
  static bool _initialized = false;
  
  // Sound effects paths - using WAV for better cross-platform compatibility
  static const String _placePieceSound = 'sounds/place.wav';
  static const String _movePieceSound = 'sounds/move.wav';
  static const String _removePieceSound = 'sounds/remove.wav';
  static const String _millSound = 'sounds/mill.wav';
  static const String _winSound = 'sounds/win.wav';
  static const String _loseSound = 'sounds/lose.wav';
  static const String _clickSound = 'sounds/click.wav';
  static const String _coinSound = 'sounds/coin.wav';
  static const String _backgroundMusic = 'sounds/background.wav';
  
  static void initialize({bool sound = true, bool music = true}) async {
    if (_initialized) return;
    
    _soundEnabled = sound;
    _musicEnabled = music;
    
    try {
      // Configure audio players for better compatibility
      await _effectPlayer.setReleaseMode(ReleaseMode.stop);
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      
      // Set volume - LOUDER for better feedback
      await _effectPlayer.setVolume(1.0);  // Max volume for effects
      await _musicPlayer.setVolume(0.5);   // Moderate for background
      
      // Enable audio context for web browsers
      await _effectPlayer.setPlayerMode(PlayerMode.lowLatency);
      
      print('🔊 Sound system initialized successfully!');
      _initialized = true;
      
      // Auto-play click sound to activate audio on web
      Future.delayed(Duration(milliseconds: 100), () {
        playClick();
      });
    } catch (e) {
      print('⚠️  Sound initialization error: $e');
      // Still mark as initialized to try playing sounds
      _initialized = true;
    }
  }
  
  static void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
    if (!enabled) {
      _effectPlayer.stop();
    }
  }
  
  static void setMusicEnabled(bool enabled) {
    _musicEnabled = enabled;
    if (enabled) {
      playBackgroundMusic();
    } else {
      _musicPlayer.stop();
    }
  }
  
  static Future<void> playSound(String sound) async {
    if (!_initialized) return;
    if (!_soundEnabled) {
      print('🔇 Sounds disabled - enable in settings');
      return;
    }
    
    try {
      await _effectPlayer.stop();
      await _effectPlayer.play(AssetSource(sound));
      print('🔊 Playing: $sound');
    } catch (e) {
      print('⚠️  Audio playback error for $sound: $e');
    }
  }
  
  static Future<void> playBackgroundMusic() async {
    if (!_musicEnabled || !_initialized) return;
    
    try {
      await _musicPlayer.play(AssetSource(_backgroundMusic));
    } catch (e) {
      // Silently fail - background music is optional
      print('Background music error: $e');
    }
  }
  
  static void stopBackgroundMusic() {
    _musicPlayer.stop();
  }
  
  // Convenience methods
  static void playPlacePiece() => playSound(_placePieceSound);
  static void playMovePiece() => playSound(_movePieceSound);
  static void playRemovePiece() => playSound(_removePieceSound);
  static void playMill() => playSound(_millSound);
  static void playWin() => playSound(_winSound);
  static void playLose() => playSound(_loseSound);
  static void playClick() => playSound(_clickSound);
  static void playCoin() => playSound(_coinSound);
  
  static void dispose() {
    _effectPlayer.dispose();
    _musicPlayer.dispose();
  }
}
