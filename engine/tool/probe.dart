// Vegël debug-u: shtyp pikët e rrënjës për çdo lëvizje, thellësi pas thellësie.
import 'package:tokerrgjik_engine/tokerrgjik_engine.dart';

String withPieces(Map<int, int> p) {
  final List<String> c = List<String>.filled(pointCount, '0');
  p.forEach((int at, int who) => c[at] = '$who');
  return c.join();
}

void main() {
  final Game g = Game.decode(
      '${withPieces(<int, int>{8: black, 9: black, 4: black, 16: black, 0: white, 5: white, 12: white, 18: white})}|1|1|1|0')!;
  print('faza=${g.phase} radha=${g.toPlay} dorë b=${g.inHand(white)} z=${g.inHand(black)}');
  for (final AiLevel lvl in <AiLevel>[AiLevel.mesatar, AiLevel.veshtire, AiLevel.shumeVeshtire, AiLevel.mjeshter]) {
    final Ai ai = Ai(lvl, seed: 5);
    final Move? m = ai.chooseMove(g);
    print('${lvl.label.padRight(18)} -> $m   (${ai.lastNodeCount} nyje)');
  }
}
