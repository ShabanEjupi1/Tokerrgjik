import 'package:test/test.dart';
import 'package:tokerrgjik_engine/tokerrgjik_engine.dart';

/// Numri i gjetheve të pemës së lëvizjeve deri në thellësinë [depth].
int perft(Game g, int depth) {
  if (depth == 0) return 1;
  final List<Move> moves = g.legalMoves();
  if (depth == 1) return moves.length;
  int total = 0;
  for (final Move m in moves) {
    g.applyUnchecked(m);
    total += perft(g, depth - 1);
    g.undo();
  }
  return total;
}

/// Rrjeta e sigurisë e gjenerimit të lëvizjeve.
///
/// Një gabim te fqinjësia, te dangjet, te fluturimi ose te objektivat e heqjes
/// ndryshon numrin e gjetheve. Testet e tjera provojnë raste të zgjedhura me
/// dorë — kjo i provon të gjitha njëherësh, dhe kap pikërisht gabimet që askush
/// nuk mendon t'i shkruajë si test.
void main() {
  group('numërimi i pemës (perft)', () {
    test('thellësia 1..4: vendosje të thjeshta, të verifikueshme me laps', () {
      // Duhen tre gurë të një lojtari për një dang, pra së paku pesë gjysmë-
      // lëvizje. Deri atje çdo pikë bosh është një lëvizje dhe asgjë tjetër.
      expect(perft(Game(), 1), 24);
      expect(perft(Game(), 2), 24 * 23);
      expect(perft(Game(), 3), 24 * 23 * 22);
      expect(perft(Game(), 4), 24 * 23 * 22 * 21);
    });

    test('thellësia 5: teprica është saktësisht numri i dangjeve të para', () {
      // Pa dangje do të ishte 255024 · 20 = 5100480. Teprica 40320 numërohet
      // veçmas dhe pajtohet:
      //   16 dangje × 3 (cilat dy pika i zë i bardhi) × 2 (radha e vendosjes)
      //   × 21 · 20 (dy gurët e zinj kudo, veç pikës që plotëson dangun)
      // Secila prej tyre shton pikërisht një lëvizje, sepse i ziu ka dy gurë
      // dhe asnjëri s'është në dang, pra ka dy objektiva heqjeje në vend të një.
      const int withoutMills = 255024 * 20;
      const int millClosing = 16 * 3 * 2 * 21 * 20;
      expect(millClosing, 40320);
      expect(perft(Game(), 5), withoutMills + millClosing);
    });

    test('thellësia 6 si rrjetë regresi', () {
      // Këtu s'ka më llogari me laps: numri doli nga ky motor. Nuk vërteton
      // asgjë vetë — por asnjë ndryshim i rregullave nuk kalon pa e lëvizur.
      expect(perft(Game(), 6), 99274176);
    }, timeout: const Timeout(Duration(minutes: 5)));
  });
}
