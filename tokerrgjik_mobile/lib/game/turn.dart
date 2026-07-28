import 'package:tokerrgjik_engine/tokerrgjik_engine.dart';

/// Përkthen prekjet e lojtarit në një [Move] të plotë.
///
/// Motori e njeh një radhë si një gjë të vetme: vendos/zhvendos DHE, nëse u
/// mbyll dang, hiq një gur. Gishti e njeh si dy ose tre prekje. Ky është i
/// vetmi vend ku ekziston ajo gjendje e ndërmjetme — dhe rri jashtë motorit me
/// qëllim, që as serveri, as AI-ja dhe as historiku të mos e shohin kurrë.
class TurnBuilder {
  TurnBuilder(this.game);

  Game game;

  /// Guri i zgjedhur për zhvendosje, ose null.
  int? selected;

  /// Lëvizjet që presin vetëm gurin që do të hiqet.
  List<Move> pendingRemovals = <Move>[];

  bool get awaitingRemoval => pendingRemovals.isNotEmpty;

  /// Ku mund të shkohet tani — pikat që ndriçohen në tabelë.
  List<int> get highlights {
    if (awaitingRemoval) return const <int>[];
    if (game.isOver) return const <int>[];

    final Set<int> out = <int>{};
    for (final Move m in game.legalMoves()) {
      if (m.isPlacement) {
        out.add(m.to);
      } else if (selected != null && m.from == selected) {
        out.add(m.to);
      }
    }
    return out.toList();
  }

  /// Gurët e kundërshtarit që mund të hiqen tani.
  List<int> get removalTargets =>
      pendingRemovals.map((Move m) => m.remove).toSet().toList();

  void reset() {
    selected = null;
    pendingRemovals = <Move>[];
  }

  /// Përpunon një prekje. Kthen lëvizjen e plotë kur radha ka mbaruar, ose null
  /// kur pritet ende një prekje tjetër.
  Move? tap(int point) {
    if (game.isOver) return null;

    if (awaitingRemoval) {
      for (final Move m in pendingRemovals) {
        if (m.remove == point) {
          reset();
          return m;
        }
      }
      // Prekje jashtë objektivave: nuk anulohet radha. Guri është vendosur
      // tashmë në mendjen e lojtarit dhe rregullat e detyrojnë heqjen —
      // anulimi këtu do të ishte një mënyrë për ta zhbërë atë.
      return null;
    }

    final List<Move> moves = game.legalMoves();
    final bool placing = moves.isNotEmpty && moves.first.isPlacement;

    if (placing) {
      return _commit(moves.where((Move m) => m.to == point).toList());
    }

    // Prekja mbi një gur të vetin: zgjidhet ose çzgjidhet.
    if (game.board[point] == game.toPlay) {
      selected = selected == point ? null : point;
      return null;
    }

    if (selected == null) return null;
    return _commit(moves
        .where((Move m) => m.from == selected && m.to == point)
        .toList());
  }

  Move? _commit(List<Move> candidates) {
    if (candidates.isEmpty) return null;
    if (candidates.length == 1) {
      reset();
      return candidates.first;
    }
    // Disa lëvizje me të njëjtin destinacion do të thotë vetëm një gjë: u mbyll
    // dang dhe ndryshojnë vetëm në gurin që hiqet.
    selected = null;
    pendingRemovals = candidates;
    return null;
  }
}

/// Teksti që i tregohet lojtarit për gjendjen e tanishme.
String turnHint(Game game, TurnBuilder builder, {String? youAre}) {
  if (game.isOver) return outcomeText(game);

  if (builder.awaitingRemoval) return 'Dang! Merr një gur të kundërshtarit.';

  final bool mine = youAre == null ||
      (youAre == 'white' && game.toPlay == white) ||
      (youAre == 'black' && game.toPlay == black);
  if (!mine) return 'Radha e kundërshtarit…';

  if (game.phase == Phase.placing) {
    return 'Vendos një gur (${game.inHand(game.toPlay)} të mbetur).';
  }
  if (game.canFly(game.toPlay)) {
    return builder.selected == null
        ? 'Tre gurë — fluturon kudo. Zgjidh një gur.'
        : 'Zgjidh ku ta çosh.';
  }
  return builder.selected == null
      ? 'Zgjidh një gur për ta lëvizur.'
      : 'Zgjidh një pikë ngjitur.';
}

String outcomeText(Game game) {
  final String why = switch (game.endReason) {
    EndReason.reducedToTwo => 'i mbetën vetëm dy gurë',
    EndReason.blocked => 'nuk kishte më asnjë lëvizje',
    EndReason.resigned => 'u dorëzua',
    EndReason.timeout => 'i mbaroi koha',
    EndReason.repetition => 'i njëjti pozicion tri herë',
    EndReason.fiftyMove => '100 lëvizje pa u marrë asnjë gur',
    EndReason.agreement => 'me marrëveshje',
    EndReason.none => '',
  };

  return switch (game.outcome) {
    Outcome.whiteWins => 'Fitoi i bardhi — $why.',
    Outcome.blackWins => 'Fitoi i ziu — $why.',
    Outcome.draw => 'Barazim — $why.',
    Outcome.none => '',
  };
}
