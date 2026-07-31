import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:tokerrgjik_engine/tokerrgjik_engine.dart';

/// Një lojtar. Nuk ka fjalëkalim dhe nuk ka email: identiteti është një token i
/// gjatë e i rastësishëm që aplikacioni e ruan në telefon.
///
/// Kjo është zgjedhje, jo dembelizëm. Aplikacioni i vjetër kërkonte regjistrim
/// për të luajtur online dhe kishte 61 llogari — pra pengesa ishte më e madhe se
/// loja. Një lojë tabele nuk ka pse t'i ruajë askujt të dhënat personale për të
/// mbajtur një pikëzim.
class Player {
  Player(this.id, this.token, this.name, {this.elo = 1200});

  final String id;
  final String token;
  String name;
  int elo;
  int wins = 0;
  int losses = 0;
  int draws = 0;
  DateTime lastSeen = DateTime.now();

  int get played => wins + losses + draws;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'token': token,
        'name': name,
        'elo': elo,
        'wins': wins,
        'losses': losses,
        'draws': draws,
        'lastSeen': lastSeen.toIso8601String(),
      };

  static Player fromJson(Map<String, dynamic> j) {
    final Player p = Player(
      j['id'] as String,
      j['token'] as String,
      j['name'] as String? ?? 'Lojtar',
      elo: (j['elo'] as num?)?.toInt() ?? 1200,
    );
    p.wins = (j['wins'] as num?)?.toInt() ?? 0;
    p.losses = (j['losses'] as num?)?.toInt() ?? 0;
    p.draws = (j['draws'] as num?)?.toInt() ?? 0;
    p.lastSeen = DateTime.tryParse(j['lastSeen'] as String? ?? '') ?? DateTime.now();
    return p;
  }

  /// Ç'ka sheh publiku. Tokeni nuk del kurrë nga këtu.
  Map<String, dynamic> toPublic() => <String, dynamic>{
        'id': id,
        'name': name,
        'elo': elo,
        'wins': wins,
        'losses': losses,
        'draws': draws,
      };
}

/// Një ndeshje mes dy lojtarëve.
class Match {
  Match(this.id, this.whiteId, this.blackId, {this.private = false, this.code})
      : game = Game(),
        startedAt = DateTime.now(),
        lastMoveAt = DateTime.now();

  final String id;
  final String whiteId;
  final String blackId;
  final bool private;
  final String? code;

  Game game;
  DateTime startedAt;
  DateTime lastMoveAt;

  /// Kush u dorëzua / kujt i mbaroi koha, që të mos rillogaritet nga tabela.
  String? resignedBy;

  /// Elo-ja para ndeshjes, që ekrani i fundit të tregojë ndryshimin.
  int whiteEloBefore = 0;
  int blackEloBefore = 0;
  int whiteEloAfter = 0;
  int blackEloAfter = 0;

  /// A janë shpërndarë tashmë pikët? Një ndeshje nuk paguan dy herë.
  bool rated = false;

  String colourOf(String playerId) {
    if (playerId == whiteId) return 'white';
    if (playerId == blackId) return 'black';
    return 'spectator';
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'whiteId': whiteId,
        'blackId': blackId,
        'private': private,
        'code': code,
        'state': game.encode(),
        'moves': game.history.map((Move m) => m.toString()).toList(),
        'outcome': game.outcome.name,
        'reason': game.endReason.name,
        'startedAt': startedAt.toIso8601String(),
        'lastMoveAt': lastMoveAt.toIso8601String(),
        'resignedBy': resignedBy,
        'whiteEloBefore': whiteEloBefore,
        'blackEloBefore': blackEloBefore,
        'whiteEloAfter': whiteEloAfter,
        'blackEloAfter': blackEloAfter,
        'rated': rated,
      };

  static Match? fromJson(Map<String, dynamic> j) {
    final Match m = Match(
      j['id'] as String,
      j['whiteId'] as String,
      j['blackId'] as String,
      private: j['private'] as bool? ?? false,
      code: j['code'] as String?,
    );

    // Gjendja rindërtohet duke RILUAJTUR lëvizjet, jo duke ngarkuar tabelën.
    // Tabela e ruajtur nuk mban dot as historikun e përsëritjeve as numëruesin e
    // barazimit; po ta ngarkonim ashtu, një server i rinisur do t'i harronte të
    // dyja dhe e njëjta ndeshje do të vazhdonte me rregulla të tjera nga ato me
    // të cilat nisi.
    final List<dynamic> moves = (j['moves'] as List<dynamic>?) ?? <dynamic>[];
    for (final dynamic raw in moves) {
      final Move? mv = Move.parse(raw as String);
      if (mv == null || !m.game.apply(mv)) return null;
    }

    final String? outcome = j['outcome'] as String?;
    if (outcome != null && outcome != Outcome.none.name && !m.game.isOver) {
      // Fundet që rregullat nuk i prodhojnë dot vetë: dorëzim, kohë, marrëveshje.
      m.game.finish(
        Outcome.values.firstWhere((Outcome o) => o.name == outcome,
            orElse: () => Outcome.none),
        EndReason.values.firstWhere(
            (EndReason r) => r.name == (j['reason'] as String? ?? ''),
            orElse: () => EndReason.none),
      );
    }

    m.startedAt = DateTime.tryParse(j['startedAt'] as String? ?? '') ?? DateTime.now();
    m.lastMoveAt = DateTime.tryParse(j['lastMoveAt'] as String? ?? '') ?? m.startedAt;
    m.resignedBy = j['resignedBy'] as String?;
    m.whiteEloBefore = (j['whiteEloBefore'] as num?)?.toInt() ?? 0;
    m.blackEloBefore = (j['blackEloBefore'] as num?)?.toInt() ?? 0;
    m.whiteEloAfter = (j['whiteEloAfter'] as num?)?.toInt() ?? 0;
    m.blackEloAfter = (j['blackEloAfter'] as num?)?.toInt() ?? 0;
    m.rated = j['rated'] as bool? ?? false;
    return m;
  }
}

/// Gjithçka që di serveri, plus ruajtja në disk.
///
/// Një skedar JSON dhe jo bazë të dhënash: aplikacioni i vjetër kishte 61
/// llogari dhe 63 lojëra pas muajsh. Një Postgres për këtë sasi është një
/// shërbim më shumë për të mirëmbajtur, një kopje rezervë më shumë për të
/// harruar, dhe 200 MB RAM në një makinë ku ato numërohen.
class Store {
  Store(this.path);

  final String path;
  final Map<String, Player> players = <String, Player>{};
  final Map<String, String> tokens = <String, String>{}; // token -> playerId
  final Map<String, Match> matches = <String, Match>{};

  /// Raportimet e lojtarëve (`POST /api/raporto`). Rrinë te i njëjti skedar si
  /// gjithçka tjetër, sepse Google Play kërkon që rruga e raportimit të mos jetë
  /// vetëm një buton që s'çon askund.
  final List<Map<String, dynamic>> reports = <Map<String, dynamic>>[];

  /// Ndeshjet e mbaruara ruhen të plota deri në këtë numër; më të vjetrat bien.
  static const int keepFinishedMatches = 400;

  /// Sa raporte mbahen. Të vjetrat bien: një regjistër që rritet pa fund do të
  /// mbushte diskun për një gjë që lexohet me sy.
  static const int keepReports = 500;

  final Random _rng = Random.secure();
  Timer? _saveTimer;
  bool _dirty = false;

  String newId([int bytes = 9]) {
    final List<int> b = List<int>.generate(bytes, (_) => _rng.nextInt(256));
    return base64Url.encode(b).replaceAll('=', '');
  }

  /// Kod dhome me shkronja pa dykuptimësi: pa 0/O dhe pa 1/I/L, sepse ky kod
  /// lexohet me zë ose shkruhet nga një ekran në një tjetër.
  String newRoomCode() {
    const String alphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
    String code;
    do {
      code = List<String>.generate(
          4, (_) => alphabet[_rng.nextInt(alphabet.length)]).join();
    } while (matches.values.any((Match m) => m.code == code && !m.game.isOver));
    return code;
  }

  Player? byToken(String? token) {
    if (token == null) return null;
    final String? id = tokens[token];
    return id == null ? null : players[id];
  }

  void touch() {
    _dirty = true;
    // Shkrimi shtyhet: një lëvizje e vetme nuk ka pse të kushtojë një shkrim në
    // disk, dhe në një ndeshje të gjallë ato vijnë çdo pak sekonda.
    _saveTimer ??= Timer(const Duration(seconds: 2), () {
      _saveTimer = null;
      if (_dirty) save();
    });
  }

  void addReport(Map<String, dynamic> entry) {
    reports.add(entry);
    while (reports.length > keepReports) {
      reports.removeAt(0);
    }
    save();
  }

  void save() {
    _dirty = false;
    _prune();
    final Map<String, dynamic> data = <String, dynamic>{
      'players': players.values.map((Player p) => p.toJson()).toList(),
      'matches': matches.values.map((Match m) => m.toJson()).toList(),
      'reports': reports,
    };
    final File f = File(path);
    f.parent.createSync(recursive: true);
    // Shkrim atomik: një server i vrarë në mes të shkrimit do të linte një JSON
    // të gjysmuar dhe do të nisej bosh herën tjetër — pra do të fshinte çdo
    // pikëzim që ekziston.
    final File tmp = File('$path.tmp');
    tmp.writeAsStringSync(jsonEncode(data));
    tmp.renameSync(path);
  }

  void _prune() {
    final List<Match> finished = matches.values
        .where((Match m) => m.game.isOver)
        .toList()
      ..sort((Match a, Match b) => b.lastMoveAt.compareTo(a.lastMoveAt));
    for (final Match m in finished.skip(keepFinishedMatches)) {
      matches.remove(m.id);
    }
  }

  void load() {
    final File f = File(path);
    if (!f.existsSync()) return;
    try {
      final Map<String, dynamic> data =
          jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
      for (final dynamic raw in (data['players'] as List<dynamic>? ?? <dynamic>[])) {
        final Player p = Player.fromJson(raw as Map<String, dynamic>);
        players[p.id] = p;
        tokens[p.token] = p.id;
      }
      for (final dynamic raw in (data['matches'] as List<dynamic>? ?? <dynamic>[])) {
        final Match? m = Match.fromJson(raw as Map<String, dynamic>);
        if (m != null) matches[m.id] = m;
      }
      for (final dynamic raw in (data['reports'] as List<dynamic>? ?? <dynamic>[])) {
        if (raw is Map<String, dynamic>) reports.add(raw);
      }
    } on Object catch (e) {
      // Një skedar i prishur nuk e ndalon serverin: më mirë të nisë bosh sesa të
      // mos nisë fare. Kopja e prishur ruhet për ta parë njeriu.
      stderr.writeln('tokerrgjik: nuk u lexua $path: $e');
      try {
        f.renameSync('$path.corrupt-${DateTime.now().millisecondsSinceEpoch}');
      } on Object catch (_) {}
      players.clear();
      tokens.clear();
      matches.clear();
      reports.clear();
    }
  }
}

/// Elo standard, K = 24.
///
/// K-ja është më e ulët se 32-shi i shahut me qëllim: kjo lojë ka shumë barazime
/// dhe ndeshje të shkurtra, dhe një K i madh e bën renditjen të kërcejë aq sa
/// nuk do të thoshte më asgjë.
({int white, int black}) eloAfter(int whiteElo, int blackElo, double whiteScore) {
  const double k = 24;
  final double expectedWhite =
      1.0 / (1.0 + pow(10, (blackElo - whiteElo) / 400.0));
  final double expectedBlack = 1.0 - expectedWhite;
  final int w = (whiteElo + k * (whiteScore - expectedWhite)).round();
  final int b = (blackElo + k * ((1.0 - whiteScore) - expectedBlack)).round();
  // Dyshemeja mbron një lojtar të ri nga një seri humbjesh që e çon në absurd.
  return (white: w < 100 ? 100 : w, black: b < 100 ? 100 : b);
}
