import 'package:flutter/foundation.dart';
import 'package:tokerrgjik_engine/tokerrgjik_engine.dart';

/// E vë kompjuterin të mendojë JASHTË fillit të ndërfaqes.
///
/// Kërkimi te niveli më i lartë zgjat deri në dy sekonda. Në fillin e
/// ndërfaqes kjo do të thotë dy sekonda pa animacione, pa prekje dhe pa
/// vizatim — Android-i e quan aplikacionin "nuk përgjigjet" dhe i ofron
/// përdoruesit ta mbyllë. Aplikacioni i vjetër e llogariste pikërisht aty.
Future<Move?> thinkMove({
  required List<String> moves,
  required int level,
}) async {
  final String? found = await compute(
    _think,
    <String, dynamic>{'moves': moves, 'level': level},
  );
  return found == null ? null : Move.parse(found);
}

/// Ekzekutohet në një isolate tjetër, ndaj merr dhe kthen vetëm tekst.
///
/// Loja rindërtohet duke riluajtur lëvizjet e jo duke dërguar tabelën: vetëm
/// kështu isolate-i i sheh edhe përsëritjet edhe numëruesin e barazimit, dhe
/// vlerëson të njëjtën lojë që sheh lojtari.
String? _think(Map<String, dynamic> args) {
  final Game g = Game();
  for (final String raw in (args['moves'] as List<dynamic>).cast<String>()) {
    final Move? m = Move.parse(raw);
    if (m == null || !g.apply(m)) return null;
  }
  final Move? best = Ai(AiLevel.fromNumber(args['level'] as int)).chooseMove(g);
  return best?.toString();
}
