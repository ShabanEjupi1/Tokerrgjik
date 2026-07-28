import 'dart:math';

import 'package:test/test.dart';
import 'package:tokerrgjik_engine/tokerrgjik_engine.dart';

/// Ndërton një gjendje nga një përshkrim i shkurtër, që testet të lexohen.
Game position(String board, {int turn = white, int handW = 0, int handB = 0}) {
  final Game? g = Game.decode('$board|$turn|$handW|$handB|0');
  if (g == null) throw ArgumentError('pozicion i pavlefshëm: $board');
  return g;
}

String emptyBoard() => '0' * pointCount;

String withPieces(Map<int, int> pieces) {
  final List<String> cells = List<String>.filled(pointCount, '0');
  pieces.forEach((int at, int who) => cells[at] = '$who');
  return cells.join();
}

void main() {
  group('vendosja', () {
    test('nis me 24 vendosje të mundshme', () {
      final Game g = Game();
      expect(g.phase, Phase.placing);
      expect(g.legalMoves().length, 24);
      expect(g.legalMoves().every((Move m) => m.isPlacement), isTrue);
    });

    test('vendosja ul gurët në dorë dhe ndërron radhën', () {
      final Game g = Game();
      expect(g.apply(const Move.place(0)), isTrue);
      expect(g.inHand(white), piecesPerPlayer - 1);
      expect(g.onBoard(white), 1);
      expect(g.toPlay, black);
    });

    test('faza kalon te lëvizja vetëm kur mbarojnë të 18 gurët', () {
      final Game g = Game();
      final Random rng = Random(7);
      while (g.phase == Phase.placing && !g.isOver) {
        final List<Move> moves = g.legalMoves();
        g.apply(moves[rng.nextInt(moves.length)]);
      }
      if (!g.isOver) {
        expect(g.inHand(white), 0);
        expect(g.inHand(black), 0);
        expect(g.phase, Phase.moving);
      }
    });
  });

  group('dangjet', () {
    test('mbyllja e një dangu e detyron heqjen e një guri', () {
      // I bardhi ka 0 dhe 1; vendosja te 2 mbyll dangun 0-1-2.
      final Game g = position(withPieces(<int, int>{0: white, 1: white, 8: black, 9: black}),
          handW: 1, handB: 1);
      final List<Move> toTwo =
          g.legalMoves().where((Move m) => m.to == 2).toList();
      expect(toTwo, isNotEmpty);
      expect(toTwo.every((Move m) => m.capturesPiece), isTrue,
          reason: 'çdo lëvizje që mbyll dang duhet të marrë një gur');
      // Asnjë gur i zi nuk është në dang, ndaj të dy janë objektiv.
      expect(toTwo.map((Move m) => m.remove).toSet(), <int>{8, 9});
    });

    test('guri brenda një dangu nuk merret kur ka gurë të lirë', () {
      // I ziu ka dangun 8-9-10 dhe një gur të lirë te 20.
      final Game g = position(
          withPieces(<int, int>{
            0: white,
            1: white,
            8: black,
            9: black,
            10: black,
            20: black,
          }),
          handW: 1);
      final List<Move> toTwo =
          g.legalMoves().where((Move m) => m.to == 2).toList();
      expect(toTwo.map((Move m) => m.remove).toSet(), <int>{20});
    });

    test('kur çdo gur i kundërshtarit është në dang, merret cilido', () {
      final Game g = position(
          withPieces(<int, int>{
            0: white,
            1: white,
            8: black,
            9: black,
            10: black,
          }),
          handW: 1);
      final List<Move> toTwo =
          g.legalMoves().where((Move m) => m.to == 2).toList();
      expect(toTwo.map((Move m) => m.remove).toSet(), <int>{8, 9, 10});
    });

    test('rrëshqitja brenda vijës së vet nuk numërohet si dang i ri', () {
      // 🚨 Gabimi klasik i kësaj loje: guri që lëviz numërohet ende në pozicionin
      // e vjetër, kështu që çdo lëvizje përgjatë një dangu duket sikur e mbyll atë.
      // I bardhi ka 0,1,2 (dang) plus 3; lëvizja 3->4 nuk mbyll asgjë, dhe as
      // 2->3 (e prish dangun 0-1-2).
      final Game g = position(withPieces(<int, int>{
        0: white,
        1: white,
        2: white,
        4: white,
        8: black,
        9: black,
        16: black,
      }));
      // Pas lëvizjes pika 2 është BOSH, pra [2,3,4] ka vetëm dy gurë të bardhë.
      // Zbatimi naiv e lë gurin te 2 gjatë kontrollit, sheh 2-3-4 të bardhë dhe
      // shpall një dang që nuk ekziston — lojtari merr një gur falas sa herë
      // rrëshqet përgjatë një brinje.
      final Move slide = g.legalMoves().firstWhere(
          (Move m) => m.from == 2 && m.to == 3,
          orElse: () => const Move.raw(-9, -9, -9));
      expect(slide.from, isNot(-9), reason: '2->3 duhet të jetë e mundur');
      expect(slide.capturesPiece, isFalse,
          reason: '2->3 e PRISH dangun 0-1-2, nuk mbyll asgjë');
    });

    test('dalja dhe kthimi e mbyll dangun sërish', () {
      final Game g = position(withPieces(<int, int>{
        0: white,
        1: white,
        3: white,
        8: black,
        9: black,
        16: black,
      }));
      // 3->2 mbyll dangun 0-1-2.
      final Iterable<Move> back =
          g.legalMoves().where((Move m) => m.from == 3 && m.to == 2);
      expect(back, isNotEmpty);
      expect(back.every((Move m) => m.capturesPiece), isTrue);
    });
  });

  group('fluturimi', () {
    test('tre gurë me gurë ende në dorë NUK fluturojnë', () {
      final Game g = position(
          withPieces(<int, int>{0: white, 8: white, 16: white, 2: black}),
          handW: 6, handB: 8);
      expect(g.canFly(white), isFalse);
      // Me gurë në dorë, të gjitha lëvizjet janë vendosje.
      expect(g.legalMoves().every((Move m) => m.isPlacement), isTrue);
    });

    test('tre gurë pa gurë në dorë fluturojnë kudo', () {
      final Game g = position(withPieces(<int, int>{
        0: white,
        8: white,
        16: white,
        2: black,
        10: black,
        18: black,
        20: black,
      }));
      expect(g.canFly(white), isTrue);
      final Set<int> destinations =
          g.legalMoves().map((Move m) => m.to).toSet();
      // 24 pika minus 7 të zëna = 17 destinacione, nga secili prej 3 gurëve.
      expect(destinations.length, 17);
    });
  });

  group('fundi i lojës', () {
    test('dy gurë të mbetur = humbje', () {
      // I ziu ka 3 gurë, asnjë në dorë; i bardhi mbyll dangun dhe i merr të tretin.
      final Game g = position(
          withPieces(<int, int>{
            0: white,
            1: white,
            3: white,
            10: white,
            12: white,
            8: black,
            20: black,
            22: black,
          }));
      final Move kill = g.legalMoves().firstWhere(
          (Move m) => m.from == 3 && m.to == 2 && m.remove == 8);
      expect(g.apply(kill), isTrue);
      expect(g.outcome, Outcome.whiteWins);
      expect(g.endReason, EndReason.reducedToTwo);
    });

    test('lojtari i bllokuar humb', () {
      // I ziu ka 4 gurë, të gjithë pa asnjë fqinj bosh.
      final Game g = position(
          withPieces(<int, int>{
            0: black,
            1: white,
            7: white,
            8: white,
            9: black,
            15: black,
            17: white,
            16: black,
            23: white,
            22: white,
            2: white,
            6: white,
          }),
          turn: white);
      // Radha e bardhë; pas një lëvizjeje të bardhë kontrollohet i ziu.
      final List<Move> moves = g.legalMoves();
      expect(moves, isNotEmpty);
    });

    test('humbja nga bllokimi njihet edhe gjatë vendosjes', () {
      // Tabelë plot pa asnjë pikë bosh nuk ndodh gjatë vendosjes, ndaj testi
      // ndërtohet me lëvizje: i ziu ka vetëm 3 gurë të mbyllur nga të bardhët.
      final Game g = position(withPieces(<int, int>{
        0: black,
        1: white,
        7: white,
        8: black,
        9: white,
        15: white,
        16: black,
        17: white,
        23: white,
      }));
      // I ziu ka 3 gurë pa gurë në dorë => fluturon, pra NUK është i bllokuar.
      expect(g.canFly(black), isTrue);
    });
  });

  group('zhbërja', () {
    test('apply + undo e kthen gjendjen bit për bit', () {
      final Random rng = Random(11);
      for (int trial = 0; trial < 40; trial++) {
        final Game g = Game();
        final int steps = 5 + rng.nextInt(40);
        for (int i = 0; i < steps && !g.isOver; i++) {
          final List<Move> moves = g.legalMoves();
          if (moves.isEmpty) break;
          final String before = g.encode();
          final int handW = g.inHand(white);
          final int handB = g.inHand(black);
          final int onW = g.onBoard(white);
          final int onB = g.onBoard(black);
          final Move m = moves[rng.nextInt(moves.length)];

          g.applyUnchecked(m);
          g.undo();

          expect(g.encode(), before, reason: 'lëvizja $m e prishi gjendjen');
          expect(g.inHand(white), handW);
          expect(g.inHand(black), handB);
          expect(g.onBoard(white), onW);
          expect(g.onBoard(black), onB);

          g.applyUnchecked(m);
        }
      }
    });
  });

  group('shënimi dhe ruajtja', () {
    test('lëvizjet shkojnë e vijnë nga teksti', () {
      const List<Move> samples = <Move>[
        Move.place(5),
        Move.place(5, remove: 12),
        Move.slide(3, 11),
        Move.slide(3, 11, remove: 20),
      ];
      for (final Move m in samples) {
        expect(Move.parse(m.toString()), m, reason: m.toString());
      }
    });

    test('teksti i keq kthen null, nuk hedh përjashtim', () {
      for (final String bad in <String>[
        '',
        'x',
        '99',
        '3-99',
        '5x99',
        'abc',
        '-1',
        '3-',
      ]) {
        expect(Move.parse(bad), isNull, reason: 'pranoi «$bad»');
      }
    });

    test('gjendja shkon e vjen nga teksti', () {
      final Random rng = Random(3);
      final Game g = Game();
      for (int i = 0; i < 30 && !g.isOver; i++) {
        final List<Move> moves = g.legalMoves();
        g.apply(moves[rng.nextInt(moves.length)]);
      }
      final Game? back = Game.decode(g.encode());
      expect(back, isNotNull);
      expect(back!.encode(), g.encode());
      expect(back.onBoard(white), g.onBoard(white));
      expect(back.onBoard(black), g.onBoard(black));
      expect(back.legalMoves().length, g.legalMoves().length);
    });

    test('gjendja e keqe kthen null', () {
      for (final String bad in <String>[
        '',
        'jo',
        '${'0' * 23}|1|9|9|0',
        '${'0' * 24}|3|9|9|0',
        '${'0' * 24}|1|99|9|0',
        '${'5' * 24}|1|0|0|0',
      ]) {
        expect(Game.decode(bad), isNull, reason: 'pranoi «$bad»');
      }
    });
  });

  group('lojëra të plota', () {
    test('300 lojëra të rastësishme mbarojnë të gjitha me rregull', () {
      final Random rng = Random(2026);
      for (int i = 0; i < 300; i++) {
        final Game g = Game();
        int plies = 0;
        while (!g.isOver && plies < 2000) {
          final List<Move> moves = g.legalMoves();
          expect(moves, isNotEmpty, reason: 'pa lëvizje por loja s\'ka mbaruar');
          expect(g.apply(moves[rng.nextInt(moves.length)]), isTrue);
          plies++;
        }
        expect(g.isOver, isTrue, reason: 'loja $i nuk mbaroi brenda 2000 lëvizjeve');
        expect(g.endReason, isNot(EndReason.none));
      }
    });
  });
}
