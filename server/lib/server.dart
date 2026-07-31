import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:tokerrgjik_engine/tokerrgjik_engine.dart';

import 'moderim.dart';
import 'store.dart';

/// Sa gjatë pret një ndeshje një lëvizje para se t'i japë fitoren tjetrit.
///
/// Pa këtë, çdo lojtar që mbyll aplikacionin lë pas një ndeshje që nuk mbaron
/// kurrë — dhe kundërshtari mbetet duke pritur në ekran pa asnjë mënyrë për të
/// dalë me pikët që i takojnë.
const Duration moveTimeout = Duration(minutes: 3);

/// Sa gjatë rri një lojtar në radhë para se të hiqet.
const Duration queueTimeout = Duration(minutes: 2);

class TokerrgjikServer {
  TokerrgjikServer(this.store);

  final Store store;

  /// playerId -> koha e hyrjes në radhë.
  final Map<String, DateTime> _queue = <String, DateTime>{};

  /// matchId -> abonentët e SSE-së.
  final Map<String, List<HttpResponse>> _streams = <String, List<HttpResponse>>{};

  Timer? _janitor;

  Future<void> start(int port) async {
    store.load();
    final HttpServer server = await HttpServer.bind(InternetAddress.anyIPv4, port);
    stdout.writeln('tokerrgjik: dëgjon në :$port  '
        '(${store.players.length} lojtarë, ${store.matches.length} ndeshje)');

    _janitor = Timer.periodic(const Duration(seconds: 20), (_) => _sweep());

    await for (final HttpRequest req in server) {
      unawaited(_handle(req).catchError((Object e, StackTrace s) {
        stderr.writeln('tokerrgjik: gabim te ${req.uri.path}: $e\n$s');
        try {
          req.response.statusCode = HttpStatus.internalServerError;
          req.response.close();
        } on Object catch (_) {}
      }));
    }
  }

  Future<void> stop() async {
    _janitor?.cancel();
    store.save();
  }

  // ── Rrugëzimi ────────────────────────────────────────────────────────────

  Future<void> _handle(HttpRequest req) async {
    final HttpResponse res = req.response;

    // Aplikacioni në web thërret nga një origjinë tjetër; ai në telefon nga
    // asnjë. Lejohet gjithçka sepse asgjë këtu nuk ndodhet pas një kukie —
    // autorizimi është tokeni te header-i, dhe një faqe e huaj nuk e ka atë.
    res.headers.set('Access-Control-Allow-Origin', '*');
    res.headers.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    res.headers.set('Access-Control-Allow-Methods', 'GET, POST, DELETE, OPTIONS');

    if (req.method == 'OPTIONS') {
      res.statusCode = HttpStatus.noContent;
      await res.close();
      return;
    }

    final List<String> seg = req.uri.pathSegments;

    if (seg.isEmpty || seg.first != 'api') {
      if (req.uri.path == '/shendeti' || req.uri.path == '/health') {
        return _json(res, <String, dynamic>{
          'ok': true,
          'players': store.players.length,
          'matches': store.matches.length,
          'queue': _queue.length,
        });
      }
      return _static(req, res);
    }

    final String route = seg.length > 1 ? seg[1] : '';

    switch (route) {
      case 'hyr':
        return _signIn(req, res);
      case 'une':
        return req.method == 'DELETE' ? _deleteAccount(req, res) : _me(req, res);
      case 'emri':
        return _rename(req, res);
      case 'rradha':
        return req.method == 'DELETE' ? _leaveQueue(req, res) : _joinQueue(req, res);
      case 'dhoma':
        return _room(req, res, seg);
      case 'loja':
        return _match(req, res, seg);
      case 'tabela':
        return _leaderboard(req, res);
      case 'raporto':
        return _report(req, res);
      default:
        return _text(res, HttpStatus.notFound, 'jo këtu');
    }
  }

  // ── Identiteti ───────────────────────────────────────────────────────────

  Future<void> _signIn(HttpRequest req, HttpResponse res) async {
    final Map<String, dynamic> body = await _body(req);
    final String? existing = _bearer(req);

    // 🚨 Emri është UGC: shfaqet te tabela e renditjes dhe te kundërshtari, ndaj
    // kalon nga filtri PARA se të ruhet. Kontrolli rri këtu e jo te aplikacioni,
    // sepse kjo derë hapet edhe me një `curl` të vetëm. Shih moderim.dart.
    final Emri? kerkuar =
        body['emri'] == null ? null : kontrolloEmrin(body['emri'] as String?);
    if (kerkuar != null && !kerkuar.ok) {
      return _text(res, HttpStatus.badRequest, kerkuar.arsyeja!);
    }

    // Aplikacioni e dërgon tokenin e vet nëse e ka: rihyrja pas rinstalimit nuk
    // duhet të krijojë një lojtar të dytë me të njëjtin emër dhe zero pikë.
    Player? p = store.byToken(existing);
    if (p == null) {
      final String id = store.newId(6);
      final String token = store.newId(24);
      p = Player(id, token, kerkuar?.emri ?? 'Lojtar');
      store.players[id] = p;
      store.tokens[token] = id;
    } else if (kerkuar != null) {
      p.name = kerkuar.emri!;
    }
    p.lastSeen = DateTime.now();
    store.touch();

    return _json(res, <String, dynamic>{
      'token': p.token,
      'lojtari': p.toPublic(),
    });
  }

  Future<void> _me(HttpRequest req, HttpResponse res) async {
    final Player? p = store.byToken(_bearer(req));
    if (p == null) return _text(res, HttpStatus.unauthorized, 'pa token');
    p.lastSeen = DateTime.now();

    // Ndeshja aktive, nëse ka: aplikacioni e hap sërish pikërisht aty ku e la.
    final Match? active = store.matches.values.firstWhereOrNull((Match m) =>
        !m.game.isOver && (m.whiteId == p.id || m.blackId == p.id));

    return _json(res, <String, dynamic>{
      'lojtari': p.toPublic(),
      'ndeshja': active == null ? null : _matchView(active, p.id),
      'neRradhe': _queue.containsKey(p.id),
    });
  }

  /// Fshirja e llogarisë. Google Play e kërkon që një llogari e krijuar brenda
  /// aplikacionit të fshihet edhe brenda tij; këtu është e lirë, sepse llogaria
  /// është një regjistrim i vetëm dhe një token.
  ///
  /// 🚨 Ndeshjet nuk fshihen, ato anonimizohen. Një ndeshje ka dy anë: po të
  /// fshihej, kundërshtari do ta gjente historikun e vet të ndryshuar dhe Elo-n
  /// e fituar nga një ndeshje që nuk ekziston më. Ndeshja aktive, nëse ka,
  /// mbyllet si dorëzim — përndryshe kundërshtari do të priste përjetësisht një
  /// lëvizje nga një lojtar që s'ekziston.
  Future<void> _deleteAccount(HttpRequest req, HttpResponse res) async {
    final Player? p = store.byToken(_bearer(req));
    if (p == null) return _text(res, HttpStatus.unauthorized, 'pa token');

    final Match? active = store.matches.values.firstWhereOrNull((Match m) =>
        !m.game.isOver && (m.whiteId == p.id || m.blackId == p.id));
    if (active != null) {
      final String colour = active.colourOf(p.id);
      active.resignedBy = p.id;
      active.game.finish(
          colour == 'white' ? Outcome.blackWins : Outcome.whiteWins,
          EndReason.resigned);
      _settle(active);
      _broadcast(active);
    }

    _queue.remove(p.id);
    store.tokens.removeWhere((String t, String id) => id == p.id);
    store.players.remove(p.id);
    store.save();

    return _json(res, <String, dynamic>{'ufshi': true});
  }

  Future<void> _rename(HttpRequest req, HttpResponse res) async {
    final Player? p = store.byToken(_bearer(req));
    if (p == null) return _text(res, HttpStatus.unauthorized, 'pa token');
    final Map<String, dynamic> body = await _body(req);

    // I njëjti filtër si te hyrja. Pa këtë, ndërrimi i emrit do të ishte dera e
    // pasme: hyn me «Arben» dhe menjëherë bëhesh çfarë të duash.
    final Emri kerkuar = kontrolloEmrin(body['emri'] as String?);
    if (!kerkuar.ok) return _text(res, HttpStatus.badRequest, kerkuar.arsyeja!);

    p.name = kerkuar.emri!;
    store.touch();
    return _json(res, <String, dynamic>{'lojtari': p.toPublic()});
  }

  /// Raportimi i një lojtari. Gjysma e dytë e rregullit të Play-t për UGC-në:
  /// filtri ndalon fjalët që dihen, raportimi kap ato që s'i di askush ende.
  ///
  /// 🔑 Raporti mban EMRIN e raportuar, jo vetëm id-në: emri është pikërisht ajo
  /// që u raportua, dhe deri sa ta shohësh ti, lojtari mund ta ketë ndërruar.
  Future<void> _report(HttpRequest req, HttpResponse res) async {
    final Player? p = store.byToken(_bearer(req));
    if (p == null) return _text(res, HttpStatus.unauthorized, 'pa token');
    if (req.method != 'POST') return _text(res, HttpStatus.notFound, 'jo këtu');

    final Map<String, dynamic> body = await _body(req);
    final String target = (body['kunder'] as String? ?? '').trim();
    final String? reason = arsyetERaportit.contains(body['arsyeja'])
        ? body['arsyeja'] as String
        : null;
    if (target.isEmpty || reason == null) {
      return _text(res, HttpStatus.badRequest, 'kërkesë e paplotë');
    }
    if (target == p.id) {
      return _text(res, HttpStatus.badRequest, 'nuk raporton dot veten');
    }

    // Një kufi i thjeshtë: pa të, raportimi me buton bëhet mjet ngacmimi dhe
    // regjistri mbushet me qindra rreshta nga i njëjti lojtar.
    final DateTime now = DateTime.now();
    final DateTime? last = _lastReport[p.id];
    if (last != null && now.difference(last) < const Duration(seconds: 30)) {
      return _text(res, 429, 'Prit pak para raportit tjetër.');
    }
    _lastReport[p.id] = now;

    store.addReport(<String, dynamic>{
      'kur': now.toIso8601String(),
      'nga': p.id,
      'ngaEmri': p.name,
      'kunder': target,
      'kunderEmri': store.players[target]?.name ?? '?',
      'arsyeja': reason,
    });
    stdout.writeln('tokerrgjik: raport ${p.id} → $target ($reason)');
    return _json(res, <String, dynamic>{'ok': true});
  }

  /// playerId -> koha e raportit të fundit. Rri në kujtesë e jo te disku: një
  /// rinisje serveri nuk është arsye për ta bllokuar raportimin.
  final Map<String, DateTime> _lastReport = <String, DateTime>{};

  // ── Radha dhe dhomat ─────────────────────────────────────────────────────

  Future<void> _joinQueue(HttpRequest req, HttpResponse res) async {
    final Player? p = store.byToken(_bearer(req));
    if (p == null) return _text(res, HttpStatus.unauthorized, 'pa token');
    p.lastSeen = DateTime.now();

    final Match? active = store.matches.values.firstWhereOrNull((Match m) =>
        !m.game.isOver && (m.whiteId == p.id || m.blackId == p.id));
    if (active != null) {
      return _json(res, <String, dynamic>{'ndeshja': _matchView(active, p.id)});
    }

    // Kundërshtari më i afërt në Elo, jo i pari që gjendet. Me pak lojtarë kjo
    // s'ka rëndësi; me shumë, ka gjithë rëndësinë.
    _queue.removeWhere((String id, DateTime at) =>
        DateTime.now().difference(at) > queueTimeout || id == p.id);

    String? bestId;
    int bestGap = 1 << 30;
    for (final String id in _queue.keys) {
      final Player? other = store.players[id];
      if (other == null) continue;
      final int gap = (other.elo - p.elo).abs();
      if (gap < bestGap) {
        bestGap = gap;
        bestId = id;
      }
    }

    if (bestId == null) {
      _queue[p.id] = DateTime.now();
      return _json(res, <String, dynamic>{'pritje': true});
    }

    _queue.remove(bestId);
    final Match m = _createMatch(bestId, p.id);
    _broadcast(m);
    return _json(res, <String, dynamic>{'ndeshja': _matchView(m, p.id)});
  }

  Future<void> _leaveQueue(HttpRequest req, HttpResponse res) async {
    final Player? p = store.byToken(_bearer(req));
    if (p == null) return _text(res, HttpStatus.unauthorized, 'pa token');
    _queue.remove(p.id);
    return _json(res, <String, dynamic>{'ok': true});
  }

  Future<void> _room(HttpRequest req, HttpResponse res, List<String> seg) async {
    final Player? p = store.byToken(_bearer(req));
    if (p == null) return _text(res, HttpStatus.unauthorized, 'pa token');
    p.lastSeen = DateTime.now();

    if (seg.length == 2) {
      // Krijo dhomë: lojtari pret, kodi i jepet mikut.
      final Match m = Match(store.newId(), p.id, '', private: true, code: store.newRoomCode());
      m.whiteEloBefore = p.elo;
      store.matches[m.id] = m;
      store.touch();
      return _json(res, <String, dynamic>{'ndeshja': _matchView(m, p.id)});
    }

    final String code = seg[2].toUpperCase();
    final Match? room = store.matches.values.firstWhereOrNull(
        (Match m) => m.code == code && m.blackId.isEmpty && !m.game.isOver);
    if (room == null) {
      return _text(res, HttpStatus.notFound, 'kjo dhomë nuk ekziston');
    }
    if (room.whiteId == p.id) {
      return _json(res, <String, dynamic>{'ndeshja': _matchView(room, p.id)});
    }

    final Match joined = Match(room.id, room.whiteId, p.id,
        private: true, code: room.code);
    joined.whiteEloBefore = store.players[room.whiteId]?.elo ?? 1200;
    joined.blackEloBefore = p.elo;
    store.matches[joined.id] = joined;
    store.touch();
    _broadcast(joined);
    return _json(res, <String, dynamic>{'ndeshja': _matchView(joined, p.id)});
  }

  Match _createMatch(String aId, String bId) {
    // Ngjyrat hidhen si short: e bardha luan e para dhe ajo epërsi nuk duhet t'i
    // takojë gjithmonë atij që priti më gjatë.
    final bool flip = DateTime.now().microsecondsSinceEpoch.isEven;
    final String w = flip ? aId : bId;
    final String b = flip ? bId : aId;
    final Match m = Match(store.newId(), w, b);
    m.whiteEloBefore = store.players[w]?.elo ?? 1200;
    m.blackEloBefore = store.players[b]?.elo ?? 1200;
    store.matches[m.id] = m;
    store.touch();
    return m;
  }

  // ── Ndeshja ──────────────────────────────────────────────────────────────

  Future<void> _match(HttpRequest req, HttpResponse res, List<String> seg) async {
    final Player? p = store.byToken(_bearer(req));
    if (p == null) return _text(res, HttpStatus.unauthorized, 'pa token');
    if (seg.length < 3) return _text(res, HttpStatus.notFound, 'pa ndeshje');

    final Match? m = store.matches[seg[2]];
    if (m == null) return _text(res, HttpStatus.notFound, 'ndeshja s\'ekziston');

    final String action = seg.length > 3 ? seg[3] : '';
    switch (action) {
      case '':
        return _json(res, <String, dynamic>{'ndeshja': _matchView(m, p.id)});
      case 'rrjedha':
        return _stream(req, res, m, p);
      case 'levizje':
        return _move(req, res, m, p);
      case 'dorezohu':
        return _resign(res, m, p);
      default:
        return _text(res, HttpStatus.notFound, 'jo këtu');
    }
  }

  Future<void> _move(HttpRequest req, HttpResponse res, Match m, Player p) async {
    if (m.game.isOver) return _text(res, HttpStatus.conflict, 'ndeshja mbaroi');

    final String colour = m.colourOf(p.id);
    if (colour == 'spectator') {
      return _text(res, HttpStatus.forbidden, 'nuk je në këtë ndeshje');
    }
    final int mine = colour == 'white' ? white : black;
    if (m.game.toPlay != mine) {
      return _text(res, HttpStatus.conflict, 'nuk është radha jote');
    }

    final Map<String, dynamic> body = await _body(req);
    final Move? move = Move.parse(body['levizja'] as String? ?? '');
    if (move == null) return _text(res, HttpStatus.badRequest, 'lëvizje e palexueshme');

    // 🔑 I njëjti `apply` që përdor telefoni. Klienti e ka tashmë të njëjtin
    // motor dhe e di përgjigjen; kjo është këtu sepse një klient i ndryshuar
    // nuk e ka.
    if (!m.game.apply(move)) {
      return _text(res, HttpStatus.badRequest, 'lëvizje e palejuar');
    }

    m.lastMoveAt = DateTime.now();
    p.lastSeen = m.lastMoveAt;
    if (m.game.isOver) _settle(m);
    store.touch();
    _broadcast(m);
    return _json(res, <String, dynamic>{'ndeshja': _matchView(m, p.id)});
  }

  Future<void> _resign(HttpResponse res, Match m, Player p) async {
    if (m.game.isOver) return _text(res, HttpStatus.conflict, 'ndeshja mbaroi');
    final String colour = m.colourOf(p.id);
    if (colour == 'spectator') {
      return _text(res, HttpStatus.forbidden, 'nuk je në këtë ndeshje');
    }
    m.resignedBy = p.id;
    m.game.finish(
        colour == 'white' ? Outcome.blackWins : Outcome.whiteWins,
        EndReason.resigned);
    _settle(m);
    store.touch();
    _broadcast(m);
    return _json(res, <String, dynamic>{'ndeshja': _matchView(m, p.id)});
  }

  /// Shpërndan Elo-n një herë të vetme për një ndeshje.
  void _settle(Match m) {
    if (m.rated) return;
    m.rated = true;

    final Player? w = store.players[m.whiteId];
    final Player? b = store.players[m.blackId];
    if (w == null || b == null) return;

    // Dhomat private nuk e prekin renditjen: dy miq mund të "dhurojnë" fitore sa
    // herë të duan, dhe një tabelë ku kjo është e mundur nuk vlen asgjë.
    if (m.private) {
      m.whiteEloAfter = w.elo;
      m.blackEloAfter = b.elo;
      return;
    }

    final double whiteScore = switch (m.game.outcome) {
      Outcome.whiteWins => 1.0,
      Outcome.blackWins => 0.0,
      _ => 0.5,
    };

    final ({int white, int black}) next = eloAfter(w.elo, b.elo, whiteScore);
    m.whiteEloBefore = w.elo;
    m.blackEloBefore = b.elo;
    w.elo = next.white;
    b.elo = next.black;
    m.whiteEloAfter = w.elo;
    m.blackEloAfter = b.elo;

    switch (m.game.outcome) {
      case Outcome.whiteWins:
        w.wins++;
        b.losses++;
      case Outcome.blackWins:
        b.wins++;
        w.losses++;
      default:
        w.draws++;
        b.draws++;
    }
  }

  // ── SSE ──────────────────────────────────────────────────────────────────

  Future<void> _stream(
      HttpRequest req, HttpResponse res, Match m, Player p) async {
    res.statusCode = HttpStatus.ok;
    res.headers
      ..set('Content-Type', 'text/event-stream; charset=utf-8')
      ..set('Cache-Control', 'no-cache, no-transform')
      ..set('Connection', 'keep-alive')
      // Pa këtë, një proxy me tampon e mban rrjedhën derisa të mbushet një bllok
      // dhe lëvizjet mbërrijnë me vonesa prej sekondash — ose fare.
      ..set('X-Accel-Buffering', 'no');
    res.bufferOutput = false;

    _streams.putIfAbsent(m.id, () => <HttpResponse>[]).add(res);

    // Gjendja e tanishme menjëherë: klienti nuk ka pse të bëjë një thirrje të
    // dytë vetëm për të mësuar se ku është loja.
    _send(res, 'gjendja', _matchView(m, p.id));

    // Rrahje zemre: një lidhje SSE pa trafik mbyllet nga ndërmjetësit brenda
    // ~100 sekondash, dhe lojtari që pret radhën e kundërshtarit nuk merr asgjë
    // për një kohë të gjatë — pikërisht atëherë kur duhet të jetë i lidhur.
    final Timer beat = Timer.periodic(const Duration(seconds: 20), (_) {
      try {
        res.write(': rreh\n\n');
      } on Object catch (_) {}
    });

    try {
      await res.done;
    } on Object catch (_) {
    } finally {
      beat.cancel();
      _streams[m.id]?.remove(res);
      if (_streams[m.id]?.isEmpty ?? false) _streams.remove(m.id);
    }
  }

  void _broadcast(Match m) {
    final List<HttpResponse>? subs = _streams[m.id];
    if (subs == null) return;
    for (final HttpResponse res in List<HttpResponse>.from(subs)) {
      try {
        // Pamja dërgohet pa këndvështrim: abonenti e di vetë ngjyrën e tij, dhe
        // një rrjedhë e vetme për të dy lojtarët do të thotë një gjendje e vetme
        // për të dy — kurrë dy versione që ndryshojnë.
        _send(res, 'gjendja', _matchView(m, null));
      } on Object catch (_) {
        subs.remove(res);
      }
    }
  }

  void _send(HttpResponse res, String event, Object data) {
    res.write('event: $event\ndata: ${jsonEncode(data)}\n\n');
  }

  // ── Tabela ───────────────────────────────────────────────────────────────

  Future<void> _leaderboard(HttpRequest req, HttpResponse res) async {
    final List<Player> top = store.players.values
        .where((Player p) => p.played > 0)
        .toList()
      ..sort((Player a, Player b) => b.elo.compareTo(a.elo));
    return _json(res, <String, dynamic>{
      'lojtaret': top.take(50).map((Player p) => p.toPublic()).toList(),
    });
  }

  // ── Pastrimi periodik ────────────────────────────────────────────────────

  void _sweep() {
    final DateTime now = DateTime.now();
    _queue.removeWhere(
        (String id, DateTime at) => now.difference(at) > queueTimeout);

    for (final Match m in store.matches.values) {
      if (m.game.isOver) continue;
      if (m.blackId.isEmpty) {
        // Dhomë private që nuk e mori kush: hiqet pa u shënuar si ndeshje.
        if (now.difference(m.startedAt) > const Duration(minutes: 30)) {
          m.game.finish(Outcome.draw, EndReason.agreement);
          m.rated = true;
        }
        continue;
      }
      if (now.difference(m.lastMoveAt) > moveTimeout) {
        final bool whiteToPlay = m.game.toPlay == white;
        m.game.finish(
            whiteToPlay ? Outcome.blackWins : Outcome.whiteWins,
            EndReason.timeout);
        _settle(m);
        _broadcast(m);
      }
    }
    store.touch();
  }

  // ── Skedarë statikë ──────────────────────────────────────────────────────

  /// Faqja publike. Serveri e shërben vetë në vend që të vihet një nginx para
  /// tij: një kontejner më pak, një konfigurim më pak, dhe asnjë mundësi që të
  /// dy të mos pajtohen se ku janë skedarët.
  Future<void> _static(HttpRequest req, HttpResponse res) async {
    final String root = Platform.environment['TOKERRGJIK_PUBLIC'] ?? 'public';
    String path = Uri.decodeComponent(req.uri.path);
    if (path.endsWith('/')) path = '${path}index.html';

    // 🚨 Normalizimi vjen PARA bashkimit me rrënjën. Pa të, një kërkesë për
    // `/../../etc/passwd` del jashtë dosjes publike — kjo është e vetmja gjë që
    // duhet bërë saktë te një shërbyes skedarësh.
    final String safe = Uri(path: path).normalizePath().path.replaceAll('\\', '/');
    if (safe.contains('..')) {
      return _text(res, HttpStatus.forbidden, 'jo');
    }

    final File f = File('$root$safe');
    if (!f.existsSync()) {
      // Aplikacioni në web ka rrugë të brendshme që s'janë skedarë; faqja e
      // parë përgjigjet për të gjitha.
      final File index = File('$root/index.html');
      if (!index.existsSync()) {
        return _text(res, HttpStatus.notFound, 'jo këtu');
      }
      return _serveFile(res, index);
    }
    return _serveFile(res, f);
  }

  Future<void> _serveFile(HttpResponse res, File f) async {
    final String ext = f.path.split('.').last.toLowerCase();
    res.headers.contentType = switch (ext) {
      'html' => ContentType.html,
      'css' => ContentType('text', 'css', charset: 'utf-8'),
      'js' => ContentType('text', 'javascript', charset: 'utf-8'),
      'json' => ContentType.json,
      'svg' => ContentType('image', 'svg+xml'),
      'png' => ContentType('image', 'png'),
      'ico' => ContentType('image', 'x-icon'),
      'wasm' => ContentType('application', 'wasm'),
      _ => ContentType.binary,
    };
    // HTML pa ruajtje, gjithçka tjetër me: Cloudflare i mbishkruan header-at
    // `no-cache` te .js/.css me katër orë (e njëjta kurth si te SpaceChess), dhe
    // asetet e Flutter-it në web kanë tashmë hash në emër.
    res.headers.set('Cache-Control',
        ext == 'html' ? 'no-cache, must-revalidate' : 'public, max-age=31536000');
    await res.addStream(f.openRead());
    await res.close();
  }

  // ── Ndihmës ──────────────────────────────────────────────────────────────

  Map<String, dynamic> _matchView(Match m, String? viewerId) {
    final Player? w = store.players[m.whiteId];
    final Player? b = m.blackId.isEmpty ? null : store.players[m.blackId];
    return <String, dynamic>{
      'id': m.id,
      'kodi': m.code,
      'private': m.private,
      'gjendja': m.game.encode(),
      'levizjet': m.game.history.map((Move mv) => mv.toString()).toList(),
      'perfundimi': m.game.outcome.name,
      'arsyeja': m.game.endReason.name,
      'radha': m.game.toPlay,
      // 🚨 `iziu` null ka kuptim: dhomë e hapur që pret mikun. Një lojtar i
      // fshirë NUK duhet të duket kështu — përndryshe një ndeshje e mbaruar do
      // t'i dukej kundërshtarit si dhomë boshe. Prandaj tombstone, jo null.
      'ibardhi': w?.toPublic() ?? _iFshire(m.whiteId),
      'iziu': m.blackId.isEmpty ? null : (b?.toPublic() ?? _iFshire(m.blackId)),
      'ngjyraIme': viewerId == null ? null : m.colourOf(viewerId),
      'eloPara': <String, int>{'w': m.whiteEloBefore, 'b': m.blackEloBefore},
      'eloPas': <String, int>{'w': m.whiteEloAfter, 'b': m.blackEloAfter},
      'levizjaFundit': m.lastMoveAt.toIso8601String(),
      'afatiSekonda': moveTimeout.inSeconds,
    };
  }

  /// Vendi i një lojtari që e ka fshirë llogarinë. Emri zëvendësohet; asgjë
  /// personale nuk mbetet, dhe ndeshja e kundërshtarit mbetet e lexueshme.
  Map<String, dynamic> _iFshire(String id) => <String, dynamic>{
        'id': id,
        'name': 'Lojtar i fshirë',
        'elo': 0,
        'wins': 0,
        'losses': 0,
        'draws': 0,
      };

  String? _bearer(HttpRequest req) {
    final String? h = req.headers.value('Authorization');
    if (h == null) return null;
    if (h.startsWith('Bearer ')) return h.substring(7).trim();
    return h.trim().isEmpty ? null : h.trim();
  }

  Future<Map<String, dynamic>> _body(HttpRequest req) async {
    try {
      final String raw = await utf8.decoder.bind(req).join();
      if (raw.trim().isEmpty) return <String, dynamic>{};
      final dynamic parsed = jsonDecode(raw);
      return parsed is Map<String, dynamic> ? parsed : <String, dynamic>{};
    } on Object catch (_) {
      return <String, dynamic>{};
    }
  }

  Future<void> _json(HttpResponse res, Map<String, dynamic> body) async {
    res.headers.contentType = ContentType.json;
    res.write(jsonEncode(body));
    await res.close();
  }

  Future<void> _text(HttpResponse res, int status, String message) async {
    res.statusCode = status;
    res.headers.contentType = ContentType.json;
    res.write(jsonEncode(<String, String>{'gabim': message}));
    await res.close();
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final T e in this) {
      if (test(e)) return e;
    }
    return null;
  }
}
