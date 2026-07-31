import 'package:shared_preferences/shared_preferences.dart';

/// Gjithçka që mbahet mend mes hapjeve: emri, tokeni online, niveli i fundit,
/// statistikat e lojës kundër kompjuterit dhe një lojë e papërfunduar.
///
/// Një `SharedPreferences` dhe jo një bazë të dhënash. Aplikacioni i vjetër
/// mbante sqflite për të ruajtur pesë numra.
class Prefs {
  Prefs(this._p);

  final SharedPreferences _p;

  static Future<Prefs> open() async => Prefs(await SharedPreferences.getInstance());

  static const String _kName = 'emri';
  static const String _kToken = 'token';
  static const String _kLevel = 'niveli';
  static const String _kSound = 'tingujt';
  static const String _kWins = 'fitore';
  static const String _kLosses = 'humbje';
  static const String _kDraws = 'barazime';
  static const String _kSaved = 'loja_e_ruajtur';
  static const String _kSavedMoves = 'loja_e_ruajtur_levizjet';
  static const String _kSavedLevel = 'loja_e_ruajtur_niveli';
  static const String _kSavedHuman = 'loja_e_ruajtur_njeriu';

  String get name => _p.getString(_kName) ?? '';
  Future<void> setName(String v) => _p.setString(_kName, v.trim());

  String? get token => _p.getString(_kToken);
  Future<void> setToken(String v) => _p.setString(_kToken, v);

  /// Pas fshirjes së llogarisë. Heq edhe emrin: po të mbetej, hyrja e radhës do
  /// ta rikrijonte menjëherë të njëjtin lojtar dhe fshirja do të dukej sikur
  /// nuk ndodhi.
  Future<void> clearToken() async {
    await _p.remove(_kToken);
    await _p.remove(_kName);
  }

  int get level => _p.getInt(_kLevel) ?? 3;
  Future<void> setLevel(int v) => _p.setInt(_kLevel, v);

  bool get sound => _p.getBool(_kSound) ?? true;
  Future<void> setSound(bool v) => _p.setBool(_kSound, v);

  int get wins => _p.getInt(_kWins) ?? 0;
  int get losses => _p.getInt(_kLosses) ?? 0;
  int get draws => _p.getInt(_kDraws) ?? 0;

  Future<void> recordResult({required bool won, required bool drew}) async {
    if (drew) {
      await _p.setInt(_kDraws, draws + 1);
    } else if (won) {
      await _p.setInt(_kWins, wins + 1);
    } else {
      await _p.setInt(_kLosses, losses + 1);
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Sfida e ditës
  //
  // 🔑 Dita numërohet e mbaruar vetëm kur FITOHET, jo kur luhet. Një humbje
  // lejon provë të re po atë ditë: ndryshe një nivel 6 do ta priste serinë e
  // dikujt që luajti mirë, dhe atëherë e vetmja lëvizje e sigurt do të ishte
  // të mos e hapje fare sfidën.
  // ───────────────────────────────────────────────────────────────────────────

  static const String _kSfida = 'sfida_data';
  static const String _kSeria = 'sfida_seria';

  /// Data e sfidës së fundit të FITUAR (`2026-08-01`), ose null.
  String? get sfidaData => _p.getString(_kSfida);

  int get sfidaSeria => _p.getInt(_kSeria) ?? 0;

  bool sfidaEBere(String data) => sfidaData == data;

  Future<void> shenoSfiden(String data, String dje) async {
    if (sfidaData == data) return;
    await _p.setInt(_kSeria, sfidaData == dje ? sfidaSeria + 1 : 1);
    await _p.setString(_kSfida, data);
  }

  /// Loja kundër kompjuterit që u la përgjysmë.
  ///
  /// Ruhen LËVIZJET dhe jo tabela: nga lëvizjet rindërtohet edhe historiku i
  /// përsëritjeve edhe numëruesi i barazimit, të cilat një tabelë e ruajtur nuk
  /// i mban. Pa këtë, një lojë e rihapur do të vazhdonte me rregulla të tjera
  /// nga ato me të cilat nisi.
  ({String moves, int level, int human})? get savedGame {
    final String? moves = _p.getString(_kSavedMoves);
    if (moves == null || moves.isEmpty) return null;
    return (
      moves: moves,
      level: _p.getInt(_kSavedLevel) ?? 3,
      human: _p.getInt(_kSavedHuman) ?? 1,
    );
  }

  Future<void> saveGame(String moves, int level, int human) async {
    await _p.setString(_kSavedMoves, moves);
    await _p.setInt(_kSavedLevel, level);
    await _p.setInt(_kSavedHuman, human);
    await _p.remove(_kSaved);
  }

  Future<void> clearSavedGame() async {
    await _p.remove(_kSavedMoves);
    await _p.remove(_kSaved);
  }
}
