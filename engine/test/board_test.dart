import 'package:test/test.dart';
import 'package:tokerrgjik_engine/tokerrgjik_engine.dart';

void main() {
  group('tabela', () {
    test('ka 24 pika dhe 16 dangje', () {
      expect(pointCount, 24);
      expect(mills.length, 16);
      expect(adjacency.length, 24);
    });

    test('fqinjësia është simetrike', () {
      for (int a = 0; a < pointCount; a++) {
        for (final int b in adjacency[a]) {
          expect(adjacency[b], contains(a),
              reason: '$a e sheh $b si fqinj, por jo anasjelltas');
        }
      }
    });

    test('asnjë pikë nuk është fqinje me vetveten', () {
      for (int a = 0; a < pointCount; a++) {
        expect(adjacency[a], isNot(contains(a)));
      }
    });

    test('shkallët janë ato të tabelës klasike (32 brinjë)', () {
      // Këndet lidhin dy pika; mesi i brinjës lidh edhe unazën ngjitur — dhe
      // vetëm unaza e mesme i ka të dyja anët, prandaj katër pika me shkallë 4.
      int edges = 0;
      for (int p = 0; p < pointCount; p++) {
        final int ring = p ~/ 8;
        final int pos = p % 8;
        final bool corner = pos.isEven;
        final int expected = corner ? 2 : (ring == 1 ? 4 : 3);
        expect(adjacency[p].length, expected, reason: 'pika $p');
        edges += adjacency[p].length;
      }
      expect(edges ~/ 2, 32);
    });

    test('çdo pikë bën pjesë në saktësisht dy dangje', () {
      for (int p = 0; p < pointCount; p++) {
        expect(millsThrough[p].length, 2, reason: 'pika $p');
      }
    });

    test('dangjet nuk përsëriten dhe kanë nga tri pika të ndryshme', () {
      final Set<String> seen = <String>{};
      for (final List<int> line in mills) {
        expect(line.length, 3);
        expect(line.toSet().length, 3);
        final List<int> sorted = List<int>.from(line)..sort();
        expect(seen.add(sorted.join(',')), isTrue, reason: 'dang i dyfishtë $line');
      }
    });

    test('pikat e një dangu unaze janë fqinje radhazi', () {
      // Katër dangjet e para të secilës unazë janë brinjë: pikat duhet të jenë
      // të lidhura fizikisht. Dangjet e shufrave (12..15) kalojnë nëpër unaza
      // dhe janë po ashtu të lidhura.
      for (final List<int> line in mills) {
        expect(adjacency[line[0]], contains(line[1]));
        expect(adjacency[line[1]], contains(line[2]));
      }
    });

    test('koordinatat janë brenda katrorit njësi dhe të gjitha të ndryshme', () {
      final Set<String> seen = <String>{};
      for (int p = 0; p < pointCount; p++) {
        expect(pointX[p], inInclusiveRange(0.0, 1.0));
        expect(pointY[p], inInclusiveRange(0.0, 1.0));
        expect(seen.add('${pointX[p]},${pointY[p]}'), isTrue,
            reason: 'pika $p bie mbi një tjetër');
      }
    });

    test('pikat e një dangu janë në një vijë të drejtë', () {
      // Nëse vizatimi dhe rregullat nuk pajtohen, loja është e saktë dhe pamja
      // gënjeshtare — gabimi më i vështirë për t'u parë te një lojë tabele.
      for (final List<int> line in mills) {
        final bool sameX =
            pointX[line[0]] == pointX[line[1]] && pointX[line[1]] == pointX[line[2]];
        final bool sameY =
            pointY[line[0]] == pointY[line[1]] && pointY[line[1]] == pointY[line[2]];
        expect(sameX || sameY, isTrue, reason: 'dangu $line nuk është vijë');
      }
    });
  });
}
