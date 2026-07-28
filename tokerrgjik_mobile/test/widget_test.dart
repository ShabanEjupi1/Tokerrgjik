import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tokerrgjik_engine/tokerrgjik_engine.dart';
import 'package:tokerrgjik_mobile/app/prefs.dart';
import 'package:tokerrgjik_mobile/app/theme.dart';
import 'package:tokerrgjik_mobile/game/board_view.dart';
import 'package:tokerrgjik_mobile/game/turn.dart';
import 'package:tokerrgjik_mobile/home_page.dart';

/// Testet e ndërfaqes mbulojnë atë që motori nuk e sheh: përkthimin e prekjes
/// në lëvizje. Kjo është e vetmja pjesë e lojës që motori s'e mbron, sepse
/// gjendja e ndërmjetme «po pres gurin që do të hiqet» ekziston vetëm këtu.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TurnBuilder', () {
    test('vendosja me një prekje kur nuk mbyllet dang', () {
      final Game g = Game();
      final TurnBuilder t = TurnBuilder(g);
      final Move? m = t.tap(5);
      expect(m, const Move.place(5));
      expect(t.awaitingRemoval, isFalse);
    });

    test('dangu kërkon një prekje të dytë mbi gurin që hiqet', () {
      // I bardhi ka 0 dhe 1 dhe një gur në dorë; 2 mbyll dangun.
      final Game? g = Game.decode(
          '${_cells(<int, int>{0: white, 1: white, 8: black, 9: black})}|1|1|1|0');
      expect(g, isNotNull);
      final TurnBuilder t = TurnBuilder(g!);

      expect(t.tap(2), isNull, reason: 'prekja e parë vetëm e hap zgjedhjen');
      expect(t.awaitingRemoval, isTrue);
      expect(t.removalTargets.toSet(), <int>{8, 9});

      // Një prekje jashtë objektivave nuk e anulon radhën: rregullat e detyrojnë
      // heqjen, dhe anulimi do të ishte një mënyrë për ta zhbërë lëvizjen.
      expect(t.tap(20), isNull);
      expect(t.awaitingRemoval, isTrue);

      final Move? done = t.tap(9);
      expect(done, const Move.place(2, remove: 9));
      expect(t.awaitingRemoval, isFalse);
    });

    test('zhvendosja zgjidhet dhe çzgjidhet me prekje mbi të njëjtin gur', () {
      final Game? g = Game.decode(
          '${_cells(<int, int>{0: white, 4: white, 12: white, 8: black, 20: black, 22: black})}|1|0|0|0');
      final TurnBuilder t = TurnBuilder(g!);

      expect(t.tap(0), isNull);
      expect(t.selected, 0);
      expect(t.highlights, isNotEmpty);

      expect(t.tap(0), isNull);
      expect(t.selected, isNull, reason: 'prekja e dytë e çzgjedh');
    });
  });

  testWidgets('ballina shfaqet dhe ka të tri mënyrat e lojës', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final Prefs prefs = await Prefs.open();

    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(),
      home: HomePage(prefs: prefs),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Tokërrgjik'), findsOneWidget);
    expect(find.text('Kundër kompjuterit'), findsOneWidget);
    expect(find.text('Dy lojtarë, një telefon'), findsOneWidget);
    expect(find.text('Luaj online'), findsOneWidget);
    // Pa lojë të ruajtur nuk ka pse të ketë buton "Vazhdo".
    expect(find.text('Vazhdo lojën'), findsNothing);
  });

  testWidgets('tabela vizatohet pa u rrëzuar në çdo fazë', (WidgetTester tester) async {
    for (final String state in <String>[
      '${'0' * 24}|1|9|9|0',
      '${_cells(<int, int>{0: white, 1: white, 8: black})}|2|7|8|0',
      '${_cells(<int, int>{0: white, 4: white, 12: white, 8: black, 20: black, 22: black})}|1|0|0|0',
    ]) {
      final Game g = Game.decode(state)!;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              height: 320,
              child: BoardView(game: g, onTap: (_) {}),
            ),
          ),
        ),
      ));
      await tester.pump();
      expect(tester.takeException(), isNull, reason: state);
    }
  });
}

String _cells(Map<int, int> pieces) {
  final List<String> c = List<String>.filled(pointCount, '0');
  pieces.forEach((int at, int who) => c[at] = '$who');
  return c.join();
}
