import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:tokerrgjik_engine/tokerrgjik_engine.dart';
import 'package:tokerrgjik_server/server.dart';
import 'package:tokerrgjik_server/store.dart';

/// Një klient i vogël HTTP, sa duhet për të luajtur një ndeshje të vërtetë.
///
/// Testet flasin me serverin përmes rrjetit dhe jo duke thirrur metodat e tij:
/// gjysma e gabimeve që ka një server janë te kufiri — kodi i statusit, tokeni
/// që s'lexohet, trupi që s'analizohet — dhe një test që i shmang ato provon
/// vetëm gjysmën e serverit.
class Client {
  Client(this.baseUrl, this.name);

  final String baseUrl;
  final String name;
  final HttpClient _http = HttpClient();
  String? token;
  String? playerId;

  Future<Map<String, dynamic>> call(String method, String path,
      [Map<String, dynamic>? body]) async {
    final HttpClientRequest req =
        await _http.openUrl(method, Uri.parse('$baseUrl$path'));
    if (token != null) req.headers.set('Authorization', 'Bearer $token');
    if (body != null) {
      req.headers.contentType = ContentType.json;
      req.write(jsonEncode(body));
    }
    final HttpClientResponse res = await req.close();
    final String text = await utf8.decoder.bind(res).join();
    final Map<String, dynamic> parsed = text.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(text) as Map<String, dynamic>;
    return <String, dynamic>{...parsed, '_status': res.statusCode};
  }

  Future<void> signIn() async {
    final Map<String, dynamic> r =
        await call('POST', '/api/hyr', <String, dynamic>{'emri': name});
    token = r['token'] as String;
    playerId = (r['lojtari'] as Map<String, dynamic>)['id'] as String;
  }

  void close() => _http.close(force: true);
}

void main() {
  late TokerrgjikServer server;
  late Store store;
  late String base;
  late Directory tmp;

  setUp(() async {
    tmp = Directory.systemTemp.createTempSync('tokerrgjik-test');
    store = Store('${tmp.path}/data.json');
    server = TokerrgjikServer(store);
    // Porta 0 = sistemi zgjedh një të lirë; testet nuk përplasen me njëri-tjetrin
    // dhe as me një server që mund të jetë duke punuar në këtë makinë.
    final ServerSocket probe = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final int port = probe.port;
    await probe.close();
    base = 'http://127.0.0.1:$port';
    unawaited(server.start(port));
    await Future<void>.delayed(const Duration(milliseconds: 150));
  });

  tearDown(() async {
    await server.stop();
    tmp.deleteSync(recursive: true);
  });

  test('hyrja krijon një lojtar dhe e mban të njëjtin me të njëjtin token',
      () async {
    final Client a = Client(base, 'Shabani');
    await a.signIn();
    expect(a.token, isNotNull);
    final String? firstId = a.playerId;

    final Map<String, dynamic> again =
        await a.call('POST', '/api/hyr', <String, dynamic>{'emri': 'Shabani'});
    expect((again['lojtari'] as Map<String, dynamic>)['id'], firstId,
        reason: 'i njëjti token duhet të japë të njëjtin lojtar');
    expect(store.players.length, 1);
    a.close();
  });

  // Filtri i emrave provohet i tëri te `moderim_test.dart`. Këtu provohet vetëm
  // që rrugët e KYÇURA e thërrasin: një filtër që ekziston por nuk lidhet askund
  // do t'i kalonte të gjitha provat e veta dhe prapë do ta linte emrin të hyjë.
  test('emri i papërshtatshëm refuzohet te hyrja dhe te ndërrimi i emrit',
      () async {
    final Client a = Client(base, 'Ardit');
    await a.signIn();

    final Map<String, dynamic> hyrje = await a
        .call('POST', '/api/hyr', <String, dynamic>{'emri': 'kurva'});
    expect(hyrje['_status'], 400);
    expect(store.players[a.playerId]!.name, 'Ardit',
        reason: 'emri i vjetër nuk preket nga një kërkesë e refuzuar');

    final Map<String, dynamic> emri = await a
        .call('POST', '/api/emri', <String, dynamic>{'emri': 'f u c k'});
    expect(emri['_status'], 400);

    final Map<String, dynamic> mire = await a
        .call('POST', '/api/emri', <String, dynamic>{'emri': 'Arbëri'});
    expect(mire['_status'], isNot(400));
    expect(store.players[a.playerId]!.name, 'Arbëri');
    a.close();
  });

  test('raportimi kërkon token, arsye të njohur dhe një tjetër lojtar',
      () async {
    final Client a = Client(base, 'Ardit');
    final Client b = Client(base, 'Blerta');
    await a.signIn();
    await b.signIn();

    expect(
        (await a.call('POST', '/api/raporto',
            <String, dynamic>{'kunder': b.playerId, 'arsyeja': 'sillet keq'}))['_status'],
        400,
        reason: 'arsyet janë listë e mbyllur');
    expect(
        (await a.call('POST', '/api/raporto',
            <String, dynamic>{'kunder': a.playerId, 'arsyeja': 'emri'}))['_status'],
        400,
        reason: 'nuk raporton dot veten');

    final Map<String, dynamic> ok = await a.call('POST', '/api/raporto',
        <String, dynamic>{'kunder': b.playerId, 'arsyeja': 'emri'});
    expect(ok['ok'], isTrue);
    expect(store.reports.length, 1);
    expect(store.reports.first['kunderEmri'], 'Blerta');

    // Kufiri i kohës: raporti i dytë brenda 30 sekondash bie me 429.
    expect(
        (await a.call('POST', '/api/raporto',
            <String, dynamic>{'kunder': b.playerId, 'arsyeja': 'sjellja'}))['_status'],
        429);
    a.close();
    b.close();
  });

  test('pa token, çdo gjë e mbrojtur kthen 401', () async {
    final Client a = Client(base, 'Askush');
    for (final List<String> r in <List<String>>[
      <String>['GET', '/api/une'],
      <String>['POST', '/api/rradha'],
      <String>['POST', '/api/dhoma'],
    ]) {
      final Map<String, dynamic> res = await a.call(r[0], r[1]);
      expect(res['_status'], 401, reason: '${r[0]} ${r[1]}');
    }
    a.close();
  });

  test('dy lojtarë në radhë çiftëzohen dhe luajnë një ndeshje të plotë',
      () async {
    final Client a = Client(base, 'Ardit');
    final Client b = Client(base, 'Blerta');
    await a.signIn();
    await b.signIn();

    final Map<String, dynamic> first = await a.call('POST', '/api/rradha');
    expect(first['pritje'], isTrue, reason: 'i pari pret');

    final Map<String, dynamic> second = await b.call('POST', '/api/rradha');
    final Map<String, dynamic> view = second['ndeshja'] as Map<String, dynamic>;
    final String matchId = view['id'] as String;
    expect(view['ibardhi'], isNotNull);
    expect(view['iziu'], isNotNull);

    // Luhet deri në fund duke i marrë lëvizjet nga motori — pra saktësisht ashtu
    // si do të bënte aplikacioni.
    final Map<String, Client> byColour = <String, Client>{};
    final String aColour =
        ((await a.call('GET', '/api/loja/$matchId'))['ndeshja']
            as Map<String, dynamic>)['ngjyraIme'] as String;
    byColour[aColour] = a;
    byColour[aColour == 'white' ? 'black' : 'white'] = b;

    Game game = Game.decode(view['gjendja'] as String)!;
    String outcome = view['perfundimi'] as String;
    int plies = 0;
    // Kushti i ndalimit lexohet nga serveri, jo nga kopja lokale: dorëzimi, koha
    // dhe barazimi nga përsëritja nuk janë të shkruara në tabelë dhe nuk mund
    // të jenë — ato udhëtojnë bashkë me gjendjen, jo brenda saj.
    while (outcome == Outcome.none.name && !game.isOver && plies < 400) {
      final Client mover = byColour[game.toPlay == white ? 'white' : 'black']!;
      final List<Move> moves = game.legalMoves();
      final Move chosen = moves[plies % moves.length];

      final Map<String, dynamic> res = await mover.call(
          'POST', '/api/loja/$matchId/levizje',
          <String, dynamic>{'levizja': chosen.toString()});
      expect(res['_status'], 200,
          reason: 'lëvizja $chosen u refuzua: ${res['gabim']}');

      final Map<String, dynamic> after = res['ndeshja'] as Map<String, dynamic>;
      game = Game.decode(after['gjendja'] as String)!;
      outcome = after['perfundimi'] as String;
      // Serveri dhe klienti duhet të bien dakord për historikun, jo vetëm për
      // tabelën: nga historiku rindërtohet gjendja pas një rinisjeje.
      expect((after['levizjet'] as List<dynamic>).length, plies + 1);
      plies++;
    }

    expect(outcome, isNot(Outcome.none.name), reason: 'ndeshja nuk mbaroi');

    // Elo-ja u lëviz dhe u lëviz vetëm një herë.
    final Map<String, dynamic> me =
        (await a.call('GET', '/api/une'))['lojtari'] as Map<String, dynamic>;
    expect(me['elo'], isNot(1200));
    final int eloAfterFirst = me['elo'] as int;
    await a.call('GET', '/api/loja/$matchId');
    final Map<String, dynamic> me2 =
        (await a.call('GET', '/api/une'))['lojtari'] as Map<String, dynamic>;
    expect(me2['elo'], eloAfterFirst, reason: 'Elo u pagua dy herë');

    a.close();
    b.close();
  }, timeout: const Timeout(Duration(minutes: 3)));

  test('serveri refuzon lëvizjet e palejuara dhe ato jashtë radhe', () async {
    final Client a = Client(base, 'Ana');
    final Client b = Client(base, 'Bora');
    await a.signIn();
    await b.signIn();
    await a.call('POST', '/api/rradha');
    final Map<String, dynamic> view =
        (await b.call('POST', '/api/rradha'))['ndeshja'] as Map<String, dynamic>;
    final String id = view['id'] as String;

    final String aColour =
        ((await a.call('GET', '/api/loja/$id'))['ndeshja']
            as Map<String, dynamic>)['ngjyraIme'] as String;
    final Client whitePlayer = aColour == 'white' ? a : b;
    final Client blackPlayer = aColour == 'white' ? b : a;

    // I ziu nuk luan i pari.
    final Map<String, dynamic> outOfTurn = await blackPlayer
        .call('POST', '/api/loja/$id/levizje', <String, dynamic>{'levizja': '0'});
    expect(outOfTurn['_status'], 409);

    // Shënim i palexueshëm.
    final Map<String, dynamic> garbage = await whitePlayer.call(
        'POST', '/api/loja/$id/levizje', <String, dynamic>{'levizja': 'jo-lëvizje'});
    expect(garbage['_status'], 400);

    // Lëvizje e lexueshme por e palejuar: në fazën e vendosjes nuk zhvendoset.
    final Map<String, dynamic> illegal = await whitePlayer.call(
        'POST', '/api/loja/$id/levizje', <String, dynamic>{'levizja': '0-1'});
    expect(illegal['_status'], 400);

    // E lejuar.
    final Map<String, dynamic> ok = await whitePlayer
        .call('POST', '/api/loja/$id/levizje', <String, dynamic>{'levizja': '0'});
    expect(ok['_status'], 200);

    // Dhe tani i njëjti lojtar nuk luan dot dy herë.
    final Map<String, dynamic> twice = await whitePlayer
        .call('POST', '/api/loja/$id/levizje', <String, dynamic>{'levizja': '1'});
    expect(twice['_status'], 409);

    a.close();
    b.close();
  });

  test('dorëzimi e mbyll ndeshjen dhe ia jep fitoren tjetrit', () async {
    final Client a = Client(base, 'Ana');
    final Client b = Client(base, 'Bora');
    await a.signIn();
    await b.signIn();
    await a.call('POST', '/api/rradha');
    final Map<String, dynamic> view =
        (await b.call('POST', '/api/rradha'))['ndeshja'] as Map<String, dynamic>;
    final String id = view['id'] as String;

    final String aColour =
        ((await a.call('GET', '/api/loja/$id'))['ndeshja']
            as Map<String, dynamic>)['ngjyraIme'] as String;

    final Map<String, dynamic> res =
        await a.call('POST', '/api/loja/$id/dorezohu');
    final Map<String, dynamic> after = res['ndeshja'] as Map<String, dynamic>;
    expect(after['arsyeja'], EndReason.resigned.name);
    expect(after['perfundimi'],
        aColour == 'white' ? Outcome.blackWins.name : Outcome.whiteWins.name);

    final Map<String, dynamic> loser =
        (await a.call('GET', '/api/une'))['lojtari'] as Map<String, dynamic>;
    expect(loser['losses'], 1);
    expect((loser['elo'] as int) < 1200, isTrue);

    a.close();
    b.close();
  });

  test('dhomat private nuk e prekin renditjen', () async {
    final Client a = Client(base, 'Miku1');
    final Client b = Client(base, 'Miku2');
    await a.signIn();
    await b.signIn();

    final Map<String, dynamic> made =
        (await a.call('POST', '/api/dhoma'))['ndeshja'] as Map<String, dynamic>;
    final String code = made['kodi'] as String;
    expect(code.length, 4);

    final Map<String, dynamic> joined =
        (await b.call('POST', '/api/dhoma/$code'))['ndeshja']
            as Map<String, dynamic>;
    expect(joined['iziu'], isNotNull);

    await a.call('POST', '/api/loja/${joined['id']}/dorezohu');
    final Map<String, dynamic> me =
        (await a.call('GET', '/api/une'))['lojtari'] as Map<String, dynamic>;
    expect(me['elo'], 1200, reason: 'dhoma private nuk duhet ta lëvizë Elo-n');

    a.close();
    b.close();
  });

  test('kodi i gabuar i dhomës kthen 404', () async {
    final Client a = Client(base, 'Ana');
    await a.signIn();
    final Map<String, dynamic> res = await a.call('POST', '/api/dhoma/ZZZZ');
    expect(res['_status'], 404);
    a.close();
  });

  test('gjendja mbijeton një rinisje të serverit', () async {
    final Client a = Client(base, 'Ana');
    final Client b = Client(base, 'Bora');
    await a.signIn();
    await b.signIn();
    await a.call('POST', '/api/rradha');
    final Map<String, dynamic> view =
        (await b.call('POST', '/api/rradha'))['ndeshja'] as Map<String, dynamic>;
    final String id = view['id'] as String;
    final String aColour =
        ((await a.call('GET', '/api/loja/$id'))['ndeshja']
            as Map<String, dynamic>)['ngjyraIme'] as String;
    final Client mover = aColour == 'white' ? a : b;
    await mover.call('POST', '/api/loja/$id/levizje', <String, dynamic>{'levizja': '5'});

    store.save();

    final Store reloaded = Store(store.path);
    reloaded.load();
    expect(reloaded.players.length, 2);
    final Match? m = reloaded.matches[id];
    expect(m, isNotNull);
    expect(m!.game.history.length, 1);
    expect(m.game.board[5], white);
    expect(m.game.toPlay, black);

    a.close();
    b.close();
  });

  test('rrjedha SSE e nis me gjendjen dhe dërgon çdo lëvizje', () async {
    final Client a = Client(base, 'Ana');
    final Client b = Client(base, 'Bora');
    await a.signIn();
    await b.signIn();
    await a.call('POST', '/api/rradha');
    final Map<String, dynamic> view =
        (await b.call('POST', '/api/rradha'))['ndeshja'] as Map<String, dynamic>;
    final String id = view['id'] as String;
    final String aColour =
        ((await a.call('GET', '/api/loja/$id'))['ndeshja']
            as Map<String, dynamic>)['ngjyraIme'] as String;
    final Client watcher = aColour == 'white' ? b : a;
    final Client mover = aColour == 'white' ? a : b;

    final HttpClient http = HttpClient();
    final HttpClientRequest req =
        await http.openUrl('GET', Uri.parse('$base/api/loja/$id/rrjedha'));
    req.headers.set('Authorization', 'Bearer ${watcher.token}');
    final HttpClientResponse res = await req.close();
    expect(res.headers.contentType?.mimeType, 'text/event-stream');

    final List<String> chunks = <String>[];
    final StreamSubscription<String> sub =
        utf8.decoder.bind(res).listen(chunks.add);

    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(chunks.join(), contains('event: gjendja'));

    await mover.call('POST', '/api/loja/$id/levizje', <String, dynamic>{'levizja': '9'});
    await Future<void>.delayed(const Duration(milliseconds: 300));

    // Ngjarja e dytë duhet të përmbajë tabelën me gurin te 9.
    final String all = chunks.join();
    expect(RegExp('event: gjendja').allMatches(all).length, greaterThanOrEqualTo(2),
        reason: 'lëvizja nuk mbërriti te abonenti');

    await sub.cancel();
    http.close(force: true);
    a.close();
    b.close();
  });
}
