import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Adresa e serverit të lojës.
///
/// E ngurtësuar dhe jo e konfigurueshme: një fushë "adresa e serverit" te
/// cilësimet është një mënyrë që një lojtar t'ia prishë vetes lojën, dhe një
/// mënyrë më shumë për t'i dërguar tokenin e vet dikujt tjetër.
const String serverBase = 'https://tokerrgjik.shabanejupi.tech';

/// Gabim i shërbimit me tekst që i tregohet lojtarit ashtu si vjen.
class ApiError implements Exception {
  ApiError(this.message, [this.status]);
  final String message;
  final int? status;
  @override
  String toString() => message;
}

/// Klienti i lojës online. Pa varësi jashtë `http`.
class Api {
  Api({http.Client? client}) : _http = client ?? http.Client();

  final http.Client _http;
  String? token;

  Map<String, String> get _headers => <String, String>{
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<Map<String, dynamic>> _send(String method, String path,
      [Map<String, dynamic>? body]) async {
    final Uri uri = Uri.parse('$serverBase$path');
    late http.Response res;
    try {
      res = switch (method) {
        'POST' => await _http
            .post(uri, headers: _headers, body: jsonEncode(body ?? <String, dynamic>{}))
            .timeout(const Duration(seconds: 15)),
        'DELETE' =>
          await _http.delete(uri, headers: _headers).timeout(const Duration(seconds: 15)),
        _ => await _http.get(uri, headers: _headers).timeout(const Duration(seconds: 15)),
      };
    } on TimeoutException {
      throw ApiError('Serveri nuk u përgjigj. Provo sërish.');
    } on Object {
      throw ApiError('Nuk ka lidhje me internetin.');
    }

    final Map<String, dynamic> parsed = res.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;

    if (res.statusCode >= 400) {
      throw ApiError(parsed['gabim'] as String? ?? 'Diçka shkoi keq.',
          res.statusCode);
    }
    return parsed;
  }

  /// Hyrja. Nëse ka tashmë një token, e dërgon dhe merr të njëjtin lojtar.
  Future<Map<String, dynamic>> signIn(String name) async {
    final Map<String, dynamic> r =
        await _send('POST', '/api/hyr', <String, dynamic>{'emri': name});
    token = r['token'] as String;
    return r['lojtari'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> me() => _send('GET', '/api/une');

  /// Fshin llogarinë te serveri. E kërkon politika e Google Play-t: një llogari
  /// e krijuar brenda aplikacionit duhet të fshihet brenda tij.
  ///
  /// 🚨 Një `401` trajtohet si sukses: do të thotë që tokeni nuk i takon më
  /// asnjë llogarie, pra fshirja tashmë ka ndodhur. Të thuhej «dështoi» do ta
  /// linte lojtarin të mendojë se të dhënat i kanë mbetur.
  Future<void> deleteAccount() async {
    try {
      await _send('DELETE', '/api/une');
    } on ApiError catch (e) {
      if (e.status != 401 && e.status != 404) rethrow;
    }
    token = null;
  }

  Future<Map<String, dynamic>> rename(String name) =>
      _send('POST', '/api/emri', <String, dynamic>{'emri': name});

  /// Raporton një lojtar tjetër. E kërkon politika e Google Play-t për
  /// përmbajtjen e krijuar nga përdoruesit: emrat shkruhen nga vetë lojtarët
  /// dhe shihen nga të gjithë, ndaj krahas filtrit te serveri duhet edhe një
  /// rrugë me të cilën lojtarët njoftojnë atë që filtri nuk e kap.
  ///
  /// Arsyet janë listë e mbyllur (`emri`, `sjellja`, `mashtrim`, `tjeter`) —
  /// një kuti me tekst të lirë do të ishte vetë UGC.
  Future<void> report(String against, String reason) async {
    await _send('POST', '/api/raporto',
        <String, dynamic>{'kunder': against, 'arsyeja': reason});
  }

  Future<Map<String, dynamic>> joinQueue() => _send('POST', '/api/rradha');

  Future<void> leaveQueue() async {
    await _send('DELETE', '/api/rradha');
  }

  Future<Map<String, dynamic>> createRoom() => _send('POST', '/api/dhoma');

  Future<Map<String, dynamic>> joinRoom(String code) =>
      _send('POST', '/api/dhoma/${Uri.encodeComponent(code.toUpperCase())}');

  Future<Map<String, dynamic>> match(String id) => _send('GET', '/api/loja/$id');

  Future<Map<String, dynamic>> play(String id, String move) => _send(
      'POST', '/api/loja/$id/levizje', <String, dynamic>{'levizja': move});

  Future<Map<String, dynamic>> resign(String id) =>
      _send('POST', '/api/loja/$id/dorezohu');

  Future<List<dynamic>> leaderboard() async {
    final Map<String, dynamic> r = await _send('GET', '/api/tabela');
    return (r['lojtaret'] as List<dynamic>?) ?? <dynamic>[];
  }

  /// Rrjedha e ndeshjes.
  ///
  /// SSE kur mundet, dhe pyetje çdo dy sekonda kur jo. Të dyja duhen: SSE-ja
  /// është e menjëhershme dhe pa kosto, por një rrjet celular që humbet lidhjen
  /// e mbyll rrjedhën në heshtje — dhe atëherë lojtari rri para një tabele që
  /// nuk lëviz më, pa asnjë shenjë se diçka nuk shkon. Rikthimi te pyetjet e
  /// mban lojën duke ecur; ai që humbet është vetëm bateria.
  Stream<Map<String, dynamic>> watch(String matchId) {
    late StreamController<Map<String, dynamic>> out;
    StreamSubscription<String>? sub;
    Timer? poll;
    bool closed = false;

    Future<void> pollOnce() async {
      if (closed) return;
      try {
        final Map<String, dynamic> r = await match(matchId);
        if (!closed) out.add(r['ndeshja'] as Map<String, dynamic>);
      } on Object {
        // Një pyetje e humbur nuk është arsye për ta mbyllur rrjedhën.
      }
    }

    void startPolling() {
      poll ??= Timer.periodic(const Duration(seconds: 2), (_) => pollOnce());
    }

    Future<void> startStream() async {
      try {
        final http.Request req = http.Request(
            'GET', Uri.parse('$serverBase/api/loja/$matchId/rrjedha'))
          ..headers.addAll(<String, String>{
            if (token != null) 'Authorization': 'Bearer $token',
            'Accept': 'text/event-stream',
          });
        final http.StreamedResponse res = await _http.send(req);
        if (res.statusCode != 200) {
          startPolling();
          return;
        }

        String buffer = '';
        sub = res.stream.transform(utf8.decoder).listen(
          (String chunk) {
            buffer += chunk;
            // Ngjarjet ndahen me një rresht bosh. Copat e ardhura nga rrjeti
            // NUK përputhen me kufijtë e ngjarjeve — një ngjarje mund të vijë
            // në tri copa dhe dy ngjarje në një. Prandaj një tampon.
            int cut;
            while ((cut = buffer.indexOf('\n\n')) >= 0) {
              final String raw = buffer.substring(0, cut);
              buffer = buffer.substring(cut + 2);
              for (final String line in raw.split('\n')) {
                if (!line.startsWith('data:')) continue;
                try {
                  final dynamic parsed = jsonDecode(line.substring(5).trim());
                  if (parsed is Map<String, dynamic> && !closed) out.add(parsed);
                } on Object {
                  // Rresht i prishur: kapërcehet, rrjedha vazhdon.
                }
              }
            }
          },
          onDone: () {
            if (!closed) startPolling();
          },
          onError: (Object _) {
            if (!closed) startPolling();
          },
          cancelOnError: false,
        );
      } on Object {
        startPolling();
      }
    }

    out = StreamController<Map<String, dynamic>>(
      onListen: () {
        unawaited(pollOnce());
        unawaited(startStream());
      },
      onCancel: () async {
        closed = true;
        poll?.cancel();
        await sub?.cancel();
      },
    );
    return out.stream;
  }

  void close() => _http.close();
}
