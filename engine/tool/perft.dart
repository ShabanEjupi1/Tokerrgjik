// Numëron gjethet e pemës së lëvizjeve deri në një thellësi të dhënë.
//
// Vlerat e prodhuara këtu ngurtësohen te `test/rules_test.dart`. Deri në
// thellësinë 4 ato verifikohen edhe me laps (24·23·22·21), pra nuk janë thjesht
// «çka nxori kodi»; nga thellësia 5 e tutje janë regres-test: nuk vërtetojnë
// rregullat, por çdo ndryshim i paqëllimtë i gjenerimit të lëvizjeve i thyen.
import 'package:tokerrgjik_engine/tokerrgjik_engine.dart';

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

void main(List<String> args) {
  final int maxDepth = args.isEmpty ? 6 : int.parse(args.first);
  for (int d = 1; d <= maxDepth; d++) {
    final Stopwatch sw = Stopwatch()..start();
    final int n = perft(Game(), d);
    sw.stop();
    print('perft($d) = $n   (${sw.elapsedMilliseconds} ms)');
  }
}
