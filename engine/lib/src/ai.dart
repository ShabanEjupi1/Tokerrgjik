import 'dart:math';

import 'board.dart';
import 'game.dart';

/// Nivelet e kompjuterit, nga më i buti te më i forti.
///
/// Emrat janë pjesë e ndërfaqes dhe prandaj rrinë këtu bashkë me sjelljen që
/// përshkruajnë: një nivel i shtuar te motori pa emër te ekrani është një nivel
/// që askush nuk e zgjedh dot.
enum AiLevel {
  fillestar(1, 'Fillestar', 1, 0.55, 250),
  leht(2, 'I lehtë', 2, 0.30, 350),
  mesatar(3, 'Mesatar', 3, 0.12, 500),
  veshtire(4, 'I vështirë', 5, 0.04, 800),
  shumeVeshtire(5, 'Shumë i vështirë', 7, 0.0, 1200),
  mjeshter(6, 'Mjeshtër', 9, 0.0, 2000);

  const AiLevel(this.number, this.label, this.maxDepth, this.blunderRate,
      this.budgetMs);

  /// 1..6, ashtu si ruhet në cilësimet e lojtarit.
  final int number;

  /// Emri që sheh lojtari.
  final String label;

  /// Thellësia maksimale e kërkimit. Tek me qëllim, në çdo nivel.
  ///
  /// Një kërkim që mbaron në një gjysmë-lëvizje të kundërshtarit e vlerëson
  /// pozicionin menjëherë pasi kundërshtari ka luajtur më të mirën e vet dhe
  /// para se ne të përgjigjemi — pra e sheh botën në momentin e saj më të keq.
  /// Kjo është arsyeja pse thellësia 6 e refuzonte një bllokim të qartë që
  /// thellësitë 3, 4 dhe 9 e zgjidhnin pa mëdyshje. Thellësitë tek e mbyllin
  /// kërkimin gjithmonë pas *sonës* dhe luajnë dukshëm më qëndrueshëm.
  final int maxDepth;

  /// Sa shpesh luan me qëllim jo lëvizjen më të mirë.
  ///
  /// Një kundërshtar i dobët duhet të *gabojë*, jo të kërkojë cekët: kërkimi me
  /// thellësi 1 luan gjithmonë të njëjtën lojë të parashikueshme dhe prapë nuk
  /// falet kurrë. Një gabim i rastësishëm herë pas here është ajo që e bën një
  /// nivel të ndihet i lehtë pa e bërë budalla.
  final double blunderRate;

  /// Kohë maksimale mendimi. Thellësia rritet hap pas hapi derisa të mbarojë.
  final int budgetMs;

  static AiLevel fromNumber(int n) {
    for (final AiLevel l in AiLevel.values) {
      if (l.number == n) return l;
    }
    return AiLevel.mesatar;
  }
}

/// Kompjuteri.
///
/// Alfa-beta me thellim të njëpasnjëshëm mbi të njëjtin [Game] që përdor edhe
/// loja — pikërisht që të mos ekzistojë një kopje e dytë e rregullave. Çdo
/// zbatim i kësaj loje që kam parë ka një gjenerues lëvizjesh për lojtarin dhe
/// një tjetër, "të shpejtë", për AI-në; dhe në secilin prej tyre, herët a vonë,
/// të dy nuk pajtohen.
class Ai {
  Ai(this.level, {int? seed}) : _rng = Random(seed);

  final AiLevel level;
  final Random _rng;

  int _nodes = 0;
  int _deadline = 0;
  bool _outOfTime = false;

  /// Sa nyje u shikuan në kërkimin e fundit. Vetëm për testet dhe për matje.
  int get lastNodeCount => _nodes;

  /// Zgjedh një lëvizje për lojtarin që ka radhën. Kthen null nëse s'ka asnjë
  /// (atëherë loja ka mbaruar tashmë).
  ///
  /// [game] nuk preket: brenda punohet mbi një kopje.
  Move? chooseMove(Game game) {
    final Game g = game.clone();
    final List<Move> moves = g.legalMoves();
    if (moves.isEmpty) return null;
    if (moves.length == 1) return moves.first;

    if (_rng.nextDouble() < level.blunderRate) {
      return moves[_rng.nextInt(moves.length)];
    }

    _nodes = 0;
    _outOfTime = false;
    _deadline = DateTime.now().millisecondsSinceEpoch + level.budgetMs;

    // Përzierja para renditjes është e vetmja burim rastësie mes lëvizjeve po aq
    // të mira, dhe duhet të jetë KËTU e jo në fund.
    //
    // Fillimisht rrënja mblidhte lëvizjet me pikë të barabarta dhe zgjidhte një
    // prej tyre. Kjo është e gabuar me alfa-beta: kur një degë bie nën dritaren
    // e kërkimit, vlera e kthyer është vetëm një kufi i sipërm dhe mund të dalë
    // saktësisht sa alfa — pra një lëvizje dukshëm më e keqe hyn në listën e
    // "barazimeve" dhe herë pas here luhet. Simptoma ishte një AI që bllokonte
    // saktë me një farë rastësie dhe e humbte bllokimin me një tjetër.
    moves.shuffle(_rng);
    _order(g, moves);

    Move best = moves.first;
    // Thellim i njëpasnjëshëm: çdo kalim jep një lëvizje të plotë dhe të
    // përdorshme, kështu që afati i kohës mund të ndërpresë kërkimin kurdo pa e
    // lënë kompjuterin pa përgjigje. Renditja e kalimit të mëparshëm e bën
    // kalimin tjetër dukshëm më të lirë.
    for (int depth = 1; depth <= level.maxDepth; depth++) {
      final _Result r = _searchRoot(g, moves, depth);
      if (_outOfTime && depth > 1) break;
      best = r.move;
      // Fitore e detyruar: asnjë thellësi më e madhe nuk e ndryshon.
      if (r.score >= _winScore - 100) break;
    }
    return best;
  }

  static const int _winScore = 100000;

  _Result _searchRoot(Game g, List<Move> moves, int depth) {
    int alpha = -_winScore * 2;
    Move best = moves.first;

    for (final Move m in moves) {
      g.applyUnchecked(m);
      final int score = -_negamax(g, depth - 1, -_winScore * 2, -alpha);
      g.undo();

      if (_outOfTime) break;

      // Rreptësisht më e mirë. Lista erdhi e përzier, ndaj mes lëvizjeve po aq
      // të mira fiton ajo që doli e para — pra një e rastësishme, pa qenë
      // nevoja të besohen pikët e degëve të prera.
      if (score > alpha) {
        alpha = score;
        best = m;
      }
    }

    return _Result(best, alpha);
  }

  int _negamax(Game g, int depth, int alpha, int beta) {
    if (g.isOver) return _terminal(g, depth);

    if ((++_nodes & 1023) == 0 &&
        DateTime.now().millisecondsSinceEpoch > _deadline) {
      _outOfTime = true;
    }
    if (_outOfTime || depth <= 0) return _evaluate(g);

    final List<Move> moves = g.legalMoves();
    if (moves.isEmpty) {
      // I bllokuar: humb ai që ka radhën.
      return -_winScore + depth;
    }
    _order(g, moves);

    int bestScore = -_winScore * 2;
    for (final Move m in moves) {
      g.applyUnchecked(m);
      final int score = -_negamax(g, depth - 1, -beta, -alpha);
      g.undo();

      if (score > bestScore) bestScore = score;
      if (bestScore > alpha) alpha = bestScore;
      if (alpha >= beta) break;
      if (_outOfTime) break;
    }
    return bestScore;
  }

  int _terminal(Game g, int depth) {
    switch (g.outcome) {
      case Outcome.draw:
        return 0;
      case Outcome.whiteWins:
        return g.toPlay == white ? _winScore + depth : -_winScore - depth;
      case Outcome.blackWins:
        return g.toPlay == black ? _winScore + depth : -_winScore - depth;
      case Outcome.none:
        return _evaluate(g);
    }
  }

  /// Lëvizjet që marrin një gur shqyrtohen të parat.
  ///
  /// Në këtë lojë marrja e një guri është e vetmja gjë e pakthyeshme, ndaj është
  /// edhe e vetmja lëvizje që pothuajse gjithmonë e ndryshon vlerësimin mjaft sa
  /// të shkaktojë një prerje alfa-beta. Vetëm kjo renditje e ul kërkimin me
  /// rreth një të tretën e nyjeve.
  void _order(Game g, List<Move> moves) {
    moves.sort((Move a, Move b) {
      final int ka = a.capturesPiece ? 1 : 0;
      final int kb = b.capturesPiece ? 1 : 0;
      return kb - ka;
    });
  }

  /// Vlerësimi statik, GJITHMONË nga këndvështrimi i atij që ka radhën.
  ///
  /// 🚨 Kjo është e gjithë marrëveshja e negamax-it dhe e vetmja gjë që duhet
  /// mbajtur mend këtu. Kërkimi e negon rezultatin në çdo shkallë; po t'i kthejë
  /// pikët nga këndvështrimi i një ngjyre të fiksuar, shenja përmbyset në
  /// thellësitë tek dhe kompjuteri zgjedh pikërisht lëvizjen më të keqe që sheh
  /// — pa u rrëzuar, pa asnjë lëvizje të palejuar, thjesht duke luajtur keq.
  /// Ashtu ishte shkruar në fillim. E kapi vetëm testi «i forti mund të dobëtin»;
  /// çdo test tjetër i AI-së kalonte pa vënë re asgjë.
  ///
  /// Peshat ndryshojnë sipas fazës sepse loja ndryshon: gjatë vendosjes numëron
  /// të ndërtuarit e formës, në lëvizje numëron liria — një lojtar me gurë më
  /// shumë por të gjithë të bllokuar ka humbur, edhe pse materiali thotë të
  /// kundërtën.
  int _evaluate(Game g) {
    final int me = g.toPlay;
    final int foe = opponentOf(me);
    final Phase phase = g.phase;

    final int pieceDiff = g.piecesLeft(me) - g.piecesLeft(foe);
    final int millDiff = g.millCount(me) - g.millCount(foe);
    final int twoDiff = _twoInLine(g, me) - _twoInLine(g, foe);
    final int mobMe = _mobility(g, me);
    final int mobFoe = _mobility(g, foe);

    // I bllokuar plotësisht = i humbur; kjo duhet të peshojë sa një fitore, që
    // kërkimi ta zgjedhë bllokimin edhe kur nuk merr asnjë gur.
    if (mobFoe == 0 && g.inHand(foe) == 0) return _winScore - 10;
    if (mobMe == 0 && g.inHand(me) == 0) return -_winScore + 10;

    switch (phase) {
      case Phase.placing:
        return 9 * pieceDiff + 20 * millDiff + 8 * twoDiff + 2 * (mobMe - mobFoe);
      case Phase.moving:
        return 12 * pieceDiff +
            34 * millDiff +
            6 * twoDiff +
            7 * (mobMe - mobFoe) +
            10 * (_doubleMills(g, me) - _doubleMills(g, foe));
      case Phase.over:
        return 0;
    }
  }

  /// Rreshtat me dy gurë të vetët dhe një pikë bosh — një dang në pritje.
  int _twoInLine(Game g, int player) {
    int n = 0;
    for (final List<int> line in mills) {
      int own = 0;
      int free = 0;
      for (final int p in line) {
        final int v = g.board[p];
        if (v == player) {
          own++;
        } else if (v == empty) {
          free++;
        }
      }
      if (own == 2 && free == 1) n++;
    }
    return n;
  }

  /// Gurët që bëjnë pjesë në dy dangje njëherësh. Një gur i tillë hap dhe mbyll
  /// një dang në çdo lëvizje: kundërshtari humb një gur në çdo radhë dhe s'ka si
  /// ta ndalë. Kjo është forma fituese e lojës dhe pa të kërkimi nuk e sheh.
  int _doubleMills(Game g, int player) {
    int n = 0;
    for (int p = 0; p < pointCount; p++) {
      if (g.board[p] != player) continue;
      int inMills = 0;
      for (final int m in millsThrough[p]) {
        final List<int> line = mills[m];
        if (g.board[line[0]] == player &&
            g.board[line[1]] == player &&
            g.board[line[2]] == player) {
          inMills++;
        }
      }
      if (inMills >= 2) n++;
    }
    return n;
  }

  /// Sa pika boshe fqinje kanë gurët e një lojtari. Gjatë vendosjes s'ka kuptim
  /// si masë lirie, ndaj peshohet lehtë atje.
  int _mobility(Game g, int player) {
    if (g.canFly(player)) {
      int freeCells = 0;
      for (int p = 0; p < pointCount; p++) {
        if (g.board[p] == empty) freeCells++;
      }
      return freeCells;
    }
    int n = 0;
    for (int from = 0; from < pointCount; from++) {
      if (g.board[from] != player) continue;
      for (final int to in adjacency[from]) {
        if (g.board[to] == empty) n++;
      }
    }
    return n;
  }
}

class _Result {
  _Result(this.move, this.score);
  final Move move;
  final int score;
}
