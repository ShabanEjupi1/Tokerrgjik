import 'board.dart';

/// Faza e lojës. Nuk ruhet — nxirret nga gjendja, që të mos ketë kurrë dy burime
/// të vërtete për të njëjtën gjë.
enum Phase {
  /// Të dy lojtarët po vendosin gurët nga dora.
  placing,

  /// Gurët lëvizin. Kush ka mbetur me tre, fluturon kudo.
  moving,

  /// Loja mbaroi.
  over,
}

/// Si përfundoi loja.
enum Outcome {
  /// Ende duke u luajtur.
  none,

  /// I bardhi fitoi.
  whiteWins,

  /// I ziu fitoi.
  blackWins,

  /// Barazim: përsëritje pozicioni ose 100 gjysmë-lëvizje pa u marrë gur.
  draw,
}

/// Pse mbaroi loja. Vetëm për tekstin që i tregohet lojtarit; rregullat nuk e
/// lexojnë kurrë.
enum EndReason {
  none,

  /// Kundërshtarit i mbetën dy gurë.
  reducedToTwo,

  /// Kundërshtari s'ka asnjë lëvizje të lejuar.
  blocked,

  /// Njëri u dorëzua.
  resigned,

  /// I mbaroi koha.
  timeout,

  /// I njëjti pozicion tri herë.
  repetition,

  /// 100 gjysmë-lëvizje pa u hequr asnjë gur.
  fiftyMove,

  /// U pranua barazimi.
  agreement,
}

/// Një lëvizje e plotë e një lojtari.
///
/// Në Tokërrgjik një radhë është ose «vendos një gur», ose «zhvendos një gur»,
/// dhe kur ajo mbyll një dang, po ajo radhë përfshin edhe heqjen e një guri të
/// kundërshtarit. Këtu janë një gjë e vetme dhe jo dy hapa, sepse gjysma e
/// gabimeve në zbatimet e kësaj loje vijnë nga një gjendje e ndërmjetme
/// "po pres që të heqë gurin", ku radha nuk i takon plotësisht askujt: rrjeti,
/// AI-ja dhe historiku duhet ta trajtojnë secili atë gjendje, dhe nuk e bëjnë
/// njëlloj. Ndërfaqja e ndan në dy prekje; motori kurrë.
class Move {
  /// Pika nga vjen guri, ose -1 kur guri vendoset nga dora.
  final int from;

  /// Pika ku shkon guri.
  final int to;

  /// Guri i kundërshtarit që hiqet, ose -1 kur kjo lëvizje nuk mbylli dang.
  final int remove;

  const Move.place(this.to, {this.remove = -1}) : from = -1;

  const Move.slide(this.from, this.to, {this.remove = -1});

  const Move.raw(this.from, this.to, this.remove);

  bool get isPlacement => from < 0;
  bool get capturesPiece => remove >= 0;

  /// Shënimi: `5` vendosje, `5x12` vendosje që hoqi gurin 12, `3-11` zhvendosje,
  /// `3-11x20` zhvendosje që hoqi gurin 20. I lexueshëm me sy — kjo është e
  /// gjithë arsyeja: një regjistër lojërash që duhet dekoduar nuk lexohet kurrë.
  @override
  String toString() {
    final String head = isPlacement ? '$to' : '$from-$to';
    return capturesPiece ? '${head}x$remove' : head;
  }

  /// E kundërta e [toString]. Kthen null për çdo tekst që nuk është shënim i
  /// vlefshëm — ky është kufiri ku mbërrijnë të dhëna nga rrjeti, dhe një
  /// përjashtim këtu do të rrëzonte serverin me një varg të keq.
  static Move? parse(String text) {
    final String s = text.trim();
    if (s.isEmpty) return null;

    int remove = -1;
    String head = s;
    final int x = s.indexOf('x');
    if (x >= 0) {
      head = s.substring(0, x);
      final int? r = int.tryParse(s.substring(x + 1));
      if (r == null || r < 0 || r >= pointCount) return null;
      remove = r;
    }

    final int dash = head.indexOf('-');
    if (dash < 0) {
      final int? to = int.tryParse(head);
      if (to == null || to < 0 || to >= pointCount) return null;
      return Move.raw(-1, to, remove);
    }

    final int? from = int.tryParse(head.substring(0, dash));
    final int? to = int.tryParse(head.substring(dash + 1));
    if (from == null || to == null) return null;
    if (from < 0 || from >= pointCount || to < 0 || to >= pointCount) return null;
    return Move.raw(from, to, remove);
  }

  @override
  bool operator ==(Object other) =>
      other is Move && other.from == from && other.to == to && other.remove == remove;

  @override
  int get hashCode => (from + 1) * 1024 + to * 32 + (remove + 1);
}

/// Ç'ka ndryshuar një lëvizje, që të kthehet pas pa e kopjuar gjithë gjendjen.
///
/// Kërkimi i AI-së kalon nëpër dhjetëra mijëra nyje; kopjimi i tabelës në secilën
/// prej tyre është pikërisht ajo që e bën një AI në telefon të duket e ngrirë.
class _Undo {
  _Undo(this.move, this.mover, this.pliesSinceCapture, this.outcome, this.reason);

  final Move move;
  final int mover;
  final int pliesSinceCapture;
  final Outcome outcome;
  final EndReason reason;
}

/// Gjendja e një loje dhe të gjitha rregullat e saj.
///
/// Ky objekt është *i ndryshueshëm* dhe i njëjti objekt përdoret edhe nga
/// kërkimi i AI-së përmes [apply] / [undo]. Kushdo që i mban një referencë duhet
/// ta dijë këtë; për një kopje të pavarur ka [clone].
class Game {
  Game()
      : board = List<int>.filled(pointCount, empty),
        _inHand = <int>[0, piecesPerPlayer, piecesPerPlayer],
        _onBoard = <int>[0, 0, 0],
        toPlay = white {
    _positionCounts[_positionKey()] = 1;
  }

  Game._bare()
      : board = List<int>.filled(pointCount, empty),
        _inHand = <int>[0, 0, 0],
        _onBoard = <int>[0, 0, 0],
        toPlay = white;

  /// 24 pika: [empty], [white] ose [black].
  final List<int> board;

  final List<int> _inHand;
  final List<int> _onBoard;

  /// Kush luan tani.
  int toPlay;

  /// Rezultati, [Outcome.none] derisa loja të mbarojë.
  Outcome outcome = Outcome.none;

  /// Pse mbaroi.
  EndReason endReason = EndReason.none;

  /// Gjysmë-lëvizjet që nga heqja e fundit e një guri. Në 100 loja barazohet.
  int pliesSinceCapture = 0;

  /// Sa herë është parë secili pozicion. Tri herë = barazim.
  final Map<int, int> _positionCounts = <int, int>{};

  final List<_Undo> _undoStack = <_Undo>[];

  /// Lëvizjet e luajtura, në shënimin e [Move.toString].
  final List<Move> history = <Move>[];

  int inHand(int player) => _inHand[player];
  int onBoard(int player) => _onBoard[player];

  /// Gurët që i kanë mbetur një lojtari gjithsej — në tabelë dhe në dorë.
  /// Nën tre, ai lojtar ka humbur.
  int piecesLeft(int player) => _inHand[player] + _onBoard[player];

  bool get isOver => outcome != Outcome.none;

  Phase get phase {
    if (isOver) return Phase.over;
    if (_inHand[white] > 0 || _inHand[black] > 0) return Phase.placing;
    return Phase.moving;
  }

  /// A fluturon ky lojtar (tre gurë, lëviz kudo)? Vetëm pasi ka mbaruar
  /// vendosja: me gurë ende në dorë, tre në tabelë është fillimi i lojës, jo
  /// fundi i saj. Kjo është një nga dy-tre vendet ku zbatimet e kësaj loje
  /// gabojnë rregullisht.
  bool canFly(int player) => _inHand[player] == 0 && _onBoard[player] == 3;

  /// A është pika [point] pjesë e një dangu të mbyllur nga [player]?
  bool isInMill(int point, int player) {
    for (final int m in millsThrough[point]) {
      final List<int> line = mills[m];
      if (board[line[0]] == player &&
          board[line[1]] == player &&
          board[line[2]] == player) {
        return true;
      }
    }
    return false;
  }

  /// Numri i dangjeve të mbyllura nga [player].
  int millCount(int player) {
    int n = 0;
    for (final List<int> line in mills) {
      if (board[line[0]] == player &&
          board[line[1]] == player &&
          board[line[2]] == player) {
        n++;
      }
    }
    return n;
  }

  /// Gurët e kundërshtarit që lejohet të hiqen tani.
  ///
  /// Rregulli: gurët brenda një dangu janë të mbrojtur — përveçse kur *të gjithë*
  /// gurët e kundërshtarit janë në dang, sepse ndryshe një dang i vetëm do ta
  /// bënte lojën të pambaruar.
  List<int> removableTargets(int mover) {
    final int foe = opponentOf(mover);
    final List<int> free = <int>[];
    final List<int> any = <int>[];
    for (int p = 0; p < pointCount; p++) {
      if (board[p] != foe) continue;
      any.add(p);
      if (!isInMill(p, foe)) free.add(p);
    }
    return free.isNotEmpty ? free : any;
  }

  /// A do ta mbyllte një dang zhvendosja e një guri të [player] nga [from] në [to]?
  ///
  /// Guri hiqet përkohësisht nga [from] përpara kontrollit: pa këtë, një gur që
  /// rrëshqet brenda vijës së vet raportohet si dang i ri sepse vetja e vjetër
  /// numërohet ende. Ky është gabimi klasik i kësaj loje.
  bool wouldCloseMill(int player, int from, int to) {
    final int savedTo = board[to];
    final int savedFrom = from >= 0 ? board[from] : empty;
    if (from >= 0) board[from] = empty;
    board[to] = player;
    final bool closed = isInMill(to, player);
    board[to] = savedTo;
    if (from >= 0) board[from] = savedFrom;
    return closed;
  }

  /// Të gjitha lëvizjet e lejuara për lojtarin që ka radhën.
  List<Move> legalMoves() {
    if (isOver) return const <Move>[];
    final int me = toPlay;
    final List<Move> out = <Move>[];

    void emit(int from, int to) {
      if (!wouldCloseMill(me, from, to)) {
        out.add(Move.raw(from, to, -1));
        return;
      }
      // Dangu i mbyllur e detyron heqjen, kështu që një lëvizje për çdo objektiv.
      final List<int> targets = _targetsAfter(me, from, to);
      if (targets.isEmpty) {
        // S'ka gur për të hequr (e mundur vetëm në pozicione të degjeneruara).
        out.add(Move.raw(from, to, -1));
        return;
      }
      for (final int t in targets) {
        out.add(Move.raw(from, to, t));
      }
    }

    if (_inHand[me] > 0) {
      for (int p = 0; p < pointCount; p++) {
        if (board[p] == empty) emit(-1, p);
      }
      return out;
    }

    final bool fly = canFly(me);
    for (int from = 0; from < pointCount; from++) {
      if (board[from] != me) continue;
      if (fly) {
        for (int to = 0; to < pointCount; to++) {
          if (board[to] == empty) emit(from, to);
        }
      } else {
        for (final int to in adjacency[from]) {
          if (board[to] == empty) emit(from, to);
        }
      }
    }
    return out;
  }

  /// Objektivat e heqjes të vlerësuar *mbi tabelën siç do të jetë* pas
  /// zhvendosjes. Guri që sapo lëvizi mund ta ketë prishur një dang të vetin, por
  /// kurrë një të kundërshtarit — prandaj mjafton të zhvendoset përkohësisht.
  List<int> _targetsAfter(int me, int from, int to) {
    final int savedTo = board[to];
    final int savedFrom = from >= 0 ? board[from] : empty;
    if (from >= 0) board[from] = empty;
    board[to] = me;
    final List<int> targets = removableTargets(me);
    board[to] = savedTo;
    if (from >= 0) board[from] = savedFrom;
    return targets;
  }

  /// A ka lojtari [me] qoftë edhe një lëvizje?
  ///
  /// Ekziston veçmas nga [legalMoves] sepse thirret pas ÇDO lëvizjeje, edhe në
  /// çdo nyje të kërkimit të AI-së, thjesht për të parë nëse kundërshtari mbeti
  /// i bllokuar. Gjenerimi i plotë provon dangje dhe objektiva heqjeje për secilën
  /// lëvizje — punë që këtu hidhet e tëra, dhe që do ta dyfishonte koston e nyjes.
  bool _hasAnyMove(int me) {
    if (_inHand[me] > 0 || canFly(me)) {
      for (int p = 0; p < pointCount; p++) {
        if (board[p] == empty) return true;
      }
      return false;
    }
    for (int from = 0; from < pointCount; from++) {
      if (board[from] != me) continue;
      for (final int to in adjacency[from]) {
        if (board[to] == empty) return true;
      }
    }
    return false;
  }

  /// A është kjo lëvizje e lejuar tani? Serveri e thërret për çdo lëvizje që
  /// vjen nga rrjeti: klienti nuk është kurrë autoriteti mbi rregullat.
  bool isLegal(Move move) {
    for (final Move m in legalMoves()) {
      if (m == move) return true;
    }
    return false;
  }

  /// Luan një lëvizje. Kthen false — pa ndryshuar asgjë — nëse s'është e lejuar.
  bool apply(Move move) {
    if (isOver) return false;
    if (!isLegal(move)) return false;
    _applyUnchecked(move);
    return true;
  }

  /// Si [apply], por pa kontrollin e ligjshmërisë. Vetëm për kërkimin e AI-së,
  /// që i merr lëvizjet nga [legalMoves] dhe s'ka nevojë t'i rivërtetojë — ai
  /// kontroll është O(numri i lëvizjeve) dhe do ta katrorëzonte kostën e nyjes.
  void applyUnchecked(Move move) => _applyUnchecked(move);

  void _applyUnchecked(Move move) {
    final int me = toPlay;
    _undoStack.add(_Undo(move, me, pliesSinceCapture, outcome, endReason));

    if (move.isPlacement) {
      _inHand[me]--;
      _onBoard[me]++;
    } else {
      board[move.from] = empty;
    }
    board[move.to] = me;

    if (move.capturesPiece) {
      final int foe = opponentOf(me);
      board[move.remove] = empty;
      _onBoard[foe]--;
      pliesSinceCapture = 0;
    } else {
      pliesSinceCapture++;
    }

    history.add(move);
    toPlay = opponentOf(me);

    final int key = _positionKey();
    _positionCounts[key] = (_positionCounts[key] ?? 0) + 1;

    _updateOutcome(me, _positionCounts[key]!);
  }

  /// Kthen mbrapsht lëvizjen e fundit. Simetrike me [applyUnchecked].
  void undo() {
    if (_undoStack.isEmpty) return;
    final _Undo u = _undoStack.removeLast();

    final int key = _positionKey();
    final int n = (_positionCounts[key] ?? 1) - 1;
    if (n <= 0) {
      _positionCounts.remove(key);
    } else {
      _positionCounts[key] = n;
    }

    final Move move = u.move;
    final int me = u.mover;

    if (move.capturesPiece) {
      final int foe = opponentOf(me);
      board[move.remove] = foe;
      _onBoard[foe]++;
    }

    board[move.to] = empty;
    if (move.isPlacement) {
      _inHand[me]++;
      _onBoard[me]--;
    } else {
      board[move.from] = me;
    }

    toPlay = me;
    pliesSinceCapture = u.pliesSinceCapture;
    outcome = u.outcome;
    endReason = u.reason;
    history.removeLast();
  }

  /// E mbyll lojën me dorë — dorëzim, koha, ose barazim i pranuar. Rregullat nuk
  /// e prodhojnë dot këtë vetë.
  void finish(Outcome result, EndReason reason) {
    outcome = result;
    endReason = reason;
  }

  void _updateOutcome(int mover, int repeats) {
    final int foe = opponentOf(mover);

    // Nën tre gurë gjithsej — në tabelë dhe në dorë — nuk mbyllet më asnjë dang,
    // ndaj loja ka mbaruar. Numërimi i gurëve *në dorë* këtu është thelbësor:
    // gjatë vendosjes një lojtar mund të bjerë në dy gurë mbi tabelë dhe ta
    // rimarrë lojën me gurët që i kanë mbetur.
    if (piecesLeft(foe) < 3) {
      outcome = mover == white ? Outcome.whiteWins : Outcome.blackWins;
      endReason = EndReason.reducedToTwo;
      return;
    }

    if (!_hasAnyMove(foe)) {
      // Kush nuk luan dot, humb. (Rregull i zakonshëm; alternativa "kalon radhën"
      // e bën lojën të pambaruar.)
      outcome = mover == white ? Outcome.whiteWins : Outcome.blackWins;
      endReason = EndReason.blocked;
      return;
    }

    if (repeats >= 3) {
      outcome = Outcome.draw;
      endReason = EndReason.repetition;
      return;
    }

    if (pliesSinceCapture >= 100) {
      outcome = Outcome.draw;
      endReason = EndReason.fiftyMove;
    }
  }

  /// Çelës i pozicionit: tabela plus kush luan.
  ///
  /// I ndarë në dy gjysma nën 2^21 dhe i bashkuar me shumëzim e mbledhje, jo me
  /// zhvendosje bitesh. Në web Dart-i përkthehet në JavaScript, ku operatorët
  /// bitë punojnë me 32 bit — një `<<` mbi 48 bit do të jepte heshtazi çelësa të
  /// përplasur, dhe kjo do të dukej si barazime nga përsëritja në lojëra që nuk
  /// përsërisnin asgjë. Shumëzimi mbetet i saktë deri në 2^53 kudo.
  int _positionKey() {
    int lo = 0;
    for (int i = 0; i < 12; i++) {
      lo = lo * 3 + board[i];
    }
    int hi = 0;
    for (int i = 12; i < pointCount; i++) {
      hi = hi * 3 + board[i];
    }
    hi = hi * 3 + toPlay;
    return lo * 2097152 + hi;
  }

  /// Kopje e pavarur. Historiku i lëvizjeve kopjohet; pirgu i kthimit prapa jo —
  /// një kopje s'ka pse të zhbëjë lëvizjet e origjinalit.
  Game clone() {
    final Game g = Game._bare();
    for (int i = 0; i < pointCount; i++) {
      g.board[i] = board[i];
    }
    g._inHand[white] = _inHand[white];
    g._inHand[black] = _inHand[black];
    g._onBoard[white] = _onBoard[white];
    g._onBoard[black] = _onBoard[black];
    g.toPlay = toPlay;
    g.outcome = outcome;
    g.endReason = endReason;
    g.pliesSinceCapture = pliesSinceCapture;
    g._positionCounts.addAll(_positionCounts);
    g.history.addAll(history);
    return g;
  }

  /// Gjendja si tekst, për ruajtje dhe për rrjetin. Formati:
  /// `<24 shifra tabele>|<radha>|<në dorë i bardhi>|<në dorë i ziu>|<gjysmë-lëvizje pa heqje>`
  String encode() {
    final StringBuffer sb = StringBuffer();
    for (int i = 0; i < pointCount; i++) {
      sb.write(board[i]);
    }
    sb.write('|$toPlay|${_inHand[white]}|${_inHand[black]}|$pliesSinceCapture');
    return sb.toString();
  }

  /// E kundërta e [encode]. Kthen null për çdo tekst të pavlefshëm — kjo hyn nga
  /// rrjeti dhe nga disku.
  static Game? decode(String text) {
    final List<String> parts = text.split('|');
    if (parts.length != 5) return null;
    if (parts[0].length != pointCount) return null;

    final Game g = Game._bare();
    for (int i = 0; i < pointCount; i++) {
      final int? v = int.tryParse(parts[0][i]);
      if (v == null || v < 0 || v > 2) return null;
      g.board[i] = v;
      if (v != empty) g._onBoard[v]++;
    }

    final int? turn = int.tryParse(parts[1]);
    final int? handW = int.tryParse(parts[2]);
    final int? handB = int.tryParse(parts[3]);
    final int? plies = int.tryParse(parts[4]);
    if (turn == null || (turn != white && turn != black)) return null;
    if (handW == null || handW < 0 || handW > piecesPerPlayer) return null;
    if (handB == null || handB < 0 || handB > piecesPerPlayer) return null;
    if (plies == null || plies < 0) return null;

    g.toPlay = turn;
    g._inHand[white] = handW;
    g._inHand[black] = handB;
    g.pliesSinceCapture = plies;
    g._positionCounts[g._positionKey()] = 1;
    g._recomputeOutcome();
    return g;
  }

  /// Nxjerr nga vetë pozicioni nëse loja ka mbaruar tashmë.
  ///
  /// 🚨 Pa këtë, një gjendje e dekoduar kthen gjithmonë `outcome == none`, edhe
  /// kur njërit lojtar i kanë mbetur dy gurë — dhe [legalMoves] ofron me
  /// gëzim lëvizje në një lojë të kryer. Serveri e kapi këtë duke refuzuar
  /// lëvizje me «ndeshja mbaroi» ndërsa klienti vazhdonte t'i dërgonte.
  ///
  /// Vetëm ato fundme që *lexohen nga tabela*. Dorëzimi, koha dhe barazimi nga
  /// përsëritja nuk janë në tabelë dhe nuk mund të jenë: ato udhëtojnë veçmas,
  /// bashkë me gjendjen.
  void _recomputeOutcome() {
    final int foe = opponentOf(toPlay);
    // Kundërshtari nën tre gurë: fiton ai që ka radhën.
    if (piecesLeft(foe) < 3) {
      outcome = toPlay == white ? Outcome.whiteWins : Outcome.blackWins;
      endReason = EndReason.reducedToTwo;
      return;
    }
    // Ai që ka radhën nën tre gurë: humb ai.
    if (piecesLeft(toPlay) < 3) {
      outcome = toPlay == white ? Outcome.blackWins : Outcome.whiteWins;
      endReason = EndReason.reducedToTwo;
      return;
    }
    if (!_hasAnyMove(toPlay)) {
      outcome = toPlay == white ? Outcome.blackWins : Outcome.whiteWins;
      endReason = EndReason.blocked;
    }
  }
}
