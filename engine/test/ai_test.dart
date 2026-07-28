import 'dart:math';

import 'package:test/test.dart';
import 'package:tokerrgjik_engine/tokerrgjik_engine.dart';

Game position(String cells, {int turn = white, int handW = 0, int handB = 0}) {
  final Game? g = Game.decode('$cells|$turn|$handW|$handB|0');
  if (g == null) throw ArgumentError('pozicion i pavlefshëm');
  return g;
}

String withPieces(Map<int, int> pieces) {
  final List<String> cells = List<String>.filled(pointCount, '0');
  pieces.forEach((int at, int who) => cells[at] = '$who');
  return cells.join();
}

/// Luan një ndeshje të plotë mes dy niveleve dhe kthen rezultatin.
Outcome playMatch(AiLevel whiteLevel, AiLevel blackLevel, int seed) {
  final Game g = Game();
  final Ai w = Ai(whiteLevel, seed: seed);
  final Ai b = Ai(blackLevel, seed: seed + 5000);
  int plies = 0;
  while (!g.isOver && plies < 500) {
    final Move? m = (g.toPlay == white ? w : b).chooseMove(g);
    if (m == null) break;
    if (!g.apply(m)) {
      throw StateError('AI kthu një lëvizje të palejuar: $m në ${g.encode()}');
    }
    plies++;
  }
  return g.outcome;
}

void main() {
  group('kompjuteri', () {
    test('kthen vetëm lëvizje të lejuara, në çdo nivel', () {
      // Kontrolli i vetëm që nuk lejohet të dështojë kurrë: një lëvizje e
      // palejuar nga AI-ja e bllokon lojën në telefonin e lojtarit, dhe në një
      // ndeshje online e shkarkon nga serveri.
      for (final AiLevel level in AiLevel.values) {
        final Ai ai = Ai(level, seed: 42);
        final Game g = Game();
        int plies = 0;
        while (!g.isOver && plies < 200) {
          final Move? m = ai.chooseMove(g);
          expect(m, isNotNull);
          expect(g.legalMoves(), contains(m),
              reason: '${level.label} luajti $m te ${g.encode()}');
          g.applyUnchecked(m!);
          plies++;
        }
      }
    }, timeout: const Timeout(Duration(minutes: 10)));

    test('nuk e prek gjendjen që i dhanë', () {
      final Game g = Game();
      g.apply(const Move.place(0));
      final String before = g.encode();
      Ai(AiLevel.veshtire, seed: 1).chooseMove(g);
      expect(g.encode(), before);
      expect(g.history.length, 1);
    });

    test('e merr fitoren kur është një lëvizje larg', () {
      // I ziu ka tre gurë dhe asnjë në dorë. I bardhi mbyll dangun 0-1-2 me
      // 3->2 dhe i merr të tretin: kjo është fitore e detyruar dhe AI-ja duhet
      // ta gjejë edhe në thellësinë më të vogël.
      final Game g = position(withPieces(<int, int>{
        0: white,
        1: white,
        3: white,
        10: white,
        12: white,
        8: black,
        20: black,
        22: black,
      }));
      for (final AiLevel level in <AiLevel>[
        AiLevel.mesatar,
        AiLevel.veshtire,
        AiLevel.shumeVeshtire,
      ]) {
        final Move? m = Ai(level, seed: 3).chooseMove(g);
        expect(m, isNotNull);
        final Game copy = g.clone();
        expect(copy.apply(m!), isTrue);
        expect(copy.outcome, Outcome.whiteWins,
            reason: '${level.label} nuk e mori fitoren: $m');
      }
    });

    test('e bllokon dangun e kundërshtarit kur nuk ka punë më të mirë', () {
      // I ziu ka 8 dhe 9 dhe një gur në dorë: 10 e mbyll dangun 8-9-10.
      //
      // Pozicioni është ndërtuar që bllokimi të jetë e vetmja lëvizje e mirë:
      // asnjë çift gurësh të bardhë nuk ndodhet në një dang me pikën e tretë
      // bosh, pra i bardhi s'ka asnjë dang për të mbyllur vetë, dhe i ziu s'ka
      // kërcënim të dytë. Pa këtë kujdes testi mat shijen e vlerësimit dhe jo
      // aftësinë për të bllokuar — versioni i parë e kishte pikërisht atë të
      // metë dhe dështonte për arsyen e gabuar.
      final Game g = position(
          withPieces(<int, int>{
            8: black,
            9: black,
            4: black,
            16: black,
            0: white,
            5: white,
            12: white,
            18: white,
          }),
          turn: white,
          handW: 1,
          handB: 1);
      final Move? m = Ai(AiLevel.shumeVeshtire, seed: 9).chooseMove(g);
      expect(m, isNotNull);
      expect(m!.to, 10, reason: 'duhet të zërë pikën që mbyll dangun e të ziut');
    });

    test('niveli i fortë mund niveli i dobët në një seri ndeshjesh', () {
      // Kjo është e vetmja provë e vërtetë që vlerësimi dhe kërkimi bëjnë punë:
      // një AI e prishur prapë kthen lëvizje të lejuara dhe prapë kalon çdo test
      // tjetër këtu. Seria është e vogël dhe me fara fikse, sepse testi duhet të
      // jetë i përsëritshëm — jo një monedhë që herë bie mirë e herë keq.
      int strongScore = 0;
      const int rounds = 6;
      for (int i = 0; i < rounds; i++) {
        // Ndërrohen ngjyrat: i bardhi ka epërsinë e lëvizjes së parë.
        final Outcome a = playMatch(AiLevel.veshtire, AiLevel.fillestar, 100 + i);
        if (a == Outcome.whiteWins) strongScore += 2;
        if (a == Outcome.draw) strongScore += 1;

        final Outcome b = playMatch(AiLevel.fillestar, AiLevel.veshtire, 200 + i);
        if (b == Outcome.blackWins) strongScore += 2;
        if (b == Outcome.draw) strongScore += 1;
      }
      // 24 pikë maksimum. Kërkohet epërsi bindëse, jo e përsosur: fillestari
      // gabon me qëllim rastësisht dhe ndonjëherë i bie mirë.
      expect(strongScore, greaterThanOrEqualTo(17),
          reason: 'i vështiri mblodhi vetëm $strongScore nga 24');
    }, timeout: const Timeout(Duration(minutes: 10)));

    test('lojë vetë-kundër-vetes mbaron gjithmonë', () {
      for (int seed = 0; seed < 4; seed++) {
        final Outcome o = playMatch(AiLevel.mesatar, AiLevel.mesatar, seed);
        expect(o, isNot(Outcome.none));
      }
    }, timeout: const Timeout(Duration(minutes: 10)));

    test('respekton buxhetin e kohës', () {
      final Game g = Game();
      // Pozicion i mesit të lojës, ku pema është e gjerë.
      final Random rng = Random(17);
      for (int i = 0; i < 14; i++) {
        final List<Move> moves = g.legalMoves();
        g.apply(moves[rng.nextInt(moves.length)]);
      }
      final Stopwatch sw = Stopwatch()..start();
      Ai(AiLevel.mjeshter, seed: 1).chooseMove(g);
      sw.stop();
      // Buxheti është 2000 ms; kontrolli i kohës bëhet çdo 1024 nyje, ndaj
      // lejohet një tepricë e vogël. Pa afat, thellësia 9 do të mendonte minuta.
      expect(sw.elapsedMilliseconds, lessThan(6000),
          reason: 'mendoi ${sw.elapsedMilliseconds} ms');
    }, timeout: const Timeout(Duration(minutes: 2)));
  });
}
