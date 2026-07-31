import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tokerrgjik_engine/tokerrgjik_engine.dart';

import '../app/ads.dart';
import '../app/prefs.dart';
import '../app/theme.dart';
import 'ai_worker.dart';
import 'board_view.dart';
import 'sfida.dart';
import 'player_bar.dart';
import 'turn.dart';

/// Lojë në këtë pajisje: kundër kompjuterit ose dy vetë mbi një telefon.
class LocalGamePage extends StatefulWidget {
  const LocalGamePage({
    super.key,
    required this.prefs,
    required this.level,
    required this.humanColour,
    this.resumeMoves = const <String>[],
    this.sfidaData,
  });

  /// Niveli i vështirësisë, ose 0 për dy lojtarë në një pajisje.
  final int level;

  /// Ngjyra e njeriut kur luhet vetëm.
  final int humanColour;

  final Prefs prefs;

  /// Lëvizjet e një loje të lënë përgjysmë.
  final List<String> resumeMoves;

  /// Data e sfidës së ditës nëse kjo lojë ËSHTË ajo sfidë, ose null.
  /// Vetëm një fitore e shënon ditën — shih `Prefs.shenoSfiden`.
  final String? sfidaData;

  bool get vsComputer => level > 0;

  @override
  State<LocalGamePage> createState() => _LocalGamePageState();
}

class _LocalGamePageState extends State<LocalGamePage> {
  late Game _game;
  late TurnBuilder _turn;
  Move? _lastMove;
  bool _thinking = false;
  bool _resultRecorded = false;

  /// Lëvizja e sugjeruar, sa kohë lojtari nuk ka luajtur ende. Mbahet veçmas
  /// nga [_lastMove] që tabela të mos e vizatojë si lëvizje të bërë.
  Move? _hint;
  bool _askingHint = false;

  @override
  void initState() {
    super.initState();
    _game = Game();
    for (final String raw in widget.resumeMoves) {
      final Move? m = Move.parse(raw);
      if (m == null || !_game.apply(m)) break;
      _lastMove = m;
    }
    _turn = TurnBuilder(_game);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeThink());
  }

  bool get _humanTurn =>
      !widget.vsComputer || _game.toPlay == widget.humanColour;

  Future<void> _maybeThink() async {
    if (!mounted || _game.isOver || _humanTurn || _thinking) return;
    setState(() => _thinking = true);

    final Move? m = await thinkMove(
      moves: _game.history.map((Move mv) => mv.toString()).toList(),
      level: widget.level,
    );

    if (!mounted) return;
    setState(() {
      _thinking = false;
      if (m != null && _game.apply(m)) {
        _lastMove = m;
        _turn.reset();
      }
    });
    _afterMove();
  }

  void _onTap(int point) {
    if (_thinking || _game.isOver || !_humanTurn) return;
    // Prekja e parë e fshin këshillën: ndryshe ndriçimi i saj do të mbulonte
    // pikat ku guri i zgjedhur mund të shkojë vërtet.
    _hint = null;
    final Move? move = _turn.tap(point);
    if (move == null) {
      setState(() {});
      return;
    }
    if (!_game.apply(move)) return;

    if (widget.prefs.sound) {
      unawaited(HapticFeedback.selectionClick());
      if (move.capturesPiece) unawaited(SystemSound.play(SystemSoundType.click));
    }
    setState(() => _lastMove = move);
    _afterMove();
  }

  /// Sa lëvizje kthen një shtypje: dy kundër kompjuterit (e jotja dhe përgjigjja
  /// e tij), një te loja me dy vetë. Të kthesh vetëm një kundër kompjuterit do
  /// ta linte radhën te ai dhe ai do të luante menjëherë sërish — pra butoni
  /// nuk do të bënte asgjë të dukshme.
  int get _sanKthehen => widget.vsComputer ? 2 : 1;

  bool get _mundKthimi =>
      !_thinking &&
      !_askingHint &&
      _game.history.length >= _sanKthehen &&
      // Pas fundit tabela është e ngrirë dhe rezultati është shkruar te
      // statistikat; një kthim atje do të thoshte fshirje e humbjes.
      !_game.isOver;

  void _kthe() {
    for (int i = 0; i < _sanKthehen; i++) {
      _game.undo();
    }
    _lastMove = _game.history.isEmpty ? null : _game.history.last;
    _hint = null;
    _turn.reset();
    unawaited(widget.prefs.saveGame(
      _game.history.map((Move m) => m.toString()).join(','),
      widget.level,
      widget.humanColour,
    ));
  }

  void _afterMove() {
    if (_game.isOver) {
      _recordResult();
      unawaited(widget.prefs.clearSavedGame());
      _showResult();
      return;
    }
    unawaited(widget.prefs.saveGame(
      _game.history.map((Move m) => m.toString()).join(','),
      widget.level,
      widget.humanColour,
    ));
    unawaited(_maybeThink());
  }

  void _recordResult() {
    // Statistikat numërojnë vetëm lojën kundër kompjuterit. Dy vetë mbi një
    // telefon nuk kanë kuptim si "fitore e jotja": pajisja nuk e di se kush e
    // mban.
    if (_resultRecorded || !widget.vsComputer) return;
    _resultRecorded = true;
    final bool drew = _game.outcome == Outcome.draw;
    final bool won = (_game.outcome == Outcome.whiteWins &&
            widget.humanColour == white) ||
        (_game.outcome == Outcome.blackWins && widget.humanColour == black);
    unawaited(widget.prefs.recordResult(won: won, drew: drew));

    final String? data = widget.sfidaData;
    if (data != null && won) {
      unawaited(widget.prefs.shenoSfiden(data, Sfida.dje(data)));
    }
  }

  /// Një këshillë kundër kompjuterit, në këmbim të një reklame të parë deri në
  /// fund.
  ///
  /// 🔑 Nëse reklama nuk vjen ose lojtari e mbyll para fundit, këshilla **jepet
  /// gjithsesi**. Ky nuk është bujari: një lojtar që pranoi ta shohë reklamën
  /// nuk duhet ndëshkuar për një rrjet reklamash që nuk u përgjigj, dhe një
  /// funksion që dështon në heshtje pas një reklame duket si mashtrim.
  /// Kompjuteri mendon te niveli më i lartë, jo te niveli i lojës — një këshillë
  /// nga një kundërshtar i dobët është më keq se asnjë këshillë.
  Future<void> _askHint() async {
    if (_askingHint || _thinking || _game.isOver || !_humanTurn) return;
    setState(() => _askingHint = true);

    await Ads.showRewarded();

    final Move? best = await thinkMove(
      moves: _game.history.map((Move mv) => mv.toString()).toList(),
      level: AiLevel.values.last.number,
    );

    if (!mounted) return;
    setState(() {
      _askingHint = false;
      _hint = best;
    });
  }

  void _showResult() => unawaited(_showResultDialog());

  /// Fundi i lojës, dhe i vetmi vend ku lejohet një reklamë e plotë ekrani.
  ///
  /// 🚨 Rendi këtu është rregull, jo rastësi: **dialogu → reklama → veprimi**.
  /// Një reklamë që hapet mbi tabelë ose para se lojtari të lexojë se fitoi apo
  /// humbi është pikërisht «reklama shkatërruese» që Play-i e ndëshkon me heqje
  /// nga dyqani. Dhe [Ads.maybeShowAfterGame] vetë vendos të mos shfaqë asgjë
  /// në shumicën e lojërave — shih kufijtë atje.
  Future<void> _showResultDialog() async {
    final bool drew = _game.outcome == Outcome.draw;
    final bool humanWon = widget.vsComputer &&
        ((_game.outcome == Outcome.whiteWins && widget.humanColour == white) ||
            (_game.outcome == Outcome.blackWins && widget.humanColour == black));

    final bool again = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) => AlertDialog(
            title: Text(
              drew
                  ? 'Barazim'
                  : widget.vsComputer
                      ? (humanWon ? 'Fitove!' : 'Humbe')
                      : (_game.outcome == Outcome.whiteWins
                          ? 'Fitoi i bardhi'
                          : 'Fitoi i ziu'),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            content: Text(outcomeText(_game)),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Dil'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Përsëri'),
              ),
            ],
          ),
        ) ??
        false;

    if (!mounted) return;
    await Ads.maybeShowAfterGame();
    if (!mounted) return;

    if (!again) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _game = Game();
      _turn = TurnBuilder(_game);
      _lastMove = null;
      _hint = null;
      _resultRecorded = false;
    });
    unawaited(_maybeThink());
  }

  Future<void> _confirmLeave() async {
    if (_game.isOver || _game.history.isEmpty) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    final bool? leave = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Ta lëmë lojën?'),
        content: const Text('Loja ruhet dhe mund ta vazhdosh më vonë.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Jo'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Po'),
          ),
        ],
      ),
    );
    if ((leave ?? false) && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    _turn.game = _game;
    final bool flipped = widget.vsComputer && widget.humanColour == black;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? _) {
        if (!didPop) unawaited(_confirmLeave());
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.vsComputer
              ? AiLevel.fromNumber(widget.level).label
              : 'Dy lojtarë'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _confirmLeave,
          ),
          actions: <Widget>[
            IconButton(
              tooltip: 'Kthe një lëvizje',
              icon: const Icon(Icons.undo),
              onPressed: _mundKthimi ? () => setState(_kthe) : null,
            ),
            // Këshilla shfaqet vetëm kundër kompjuterit dhe vetëm kur radha e ke
            // ti: te loja me dy vetë mbi një telefon do të ishte thjesht mashtrim
            // ndaj tjetrit që rri përballë.
            if (widget.vsComputer && Ads.supported)
              IconButton(
                tooltip: 'Këshillë (shiko një reklamë)',
                icon: _askingHint
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.lightbulb_outline),
                onPressed: _humanTurn && !_game.isOver && !_askingHint
                    ? () => unawaited(_askHint())
                    : null,
              ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: <Widget>[
                PlayerBar(
                  game: _game,
                  colour: flipped ? white : black,
                  name: _nameFor(flipped ? white : black),
                  active: _game.toPlay == (flipped ? white : black),
                  thinking: _thinking && !_humanTurn,
                ),
                Expanded(
                  child: Center(
                    child: BoardView(
                      game: _game,
                      onTap: _onTap,
                      selected: _turn.selected,
                      // Kur ka një këshillë të papërdorur, ndriçohen pikat e saj
                      // — pika ku duhet vendosur guri, ose të dyja pikat e
                      // zhvendosjes. Sapo lojtari luan diçka, [_hint] fshihet.
                      highlighted: _hint != null
                          ? <int>[
                              if (!_hint!.isPlacement) _hint!.from,
                              _hint!.to,
                            ]
                          : (_humanTurn ? _turn.highlights : const <int>[]),
                      removable: _turn.removalTargets,
                      lastMove: _lastMove,
                      flipped: flipped,
                    ),
                  ),
                ),
                PlayerBar(
                  game: _game,
                  colour: flipped ? black : white,
                  name: _nameFor(flipped ? black : white),
                  active: _game.toPlay == (flipped ? black : white),
                  thinking: false,
                ),
                const SizedBox(height: 12),
                Text(
                  turnHint(_game, _turn),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Palette.textDim, fontSize: 15),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _nameFor(int colour) {
    if (!widget.vsComputer) return colour == white ? 'I bardhi' : 'I ziu';
    return colour == widget.humanColour
        ? (widget.prefs.name.isEmpty ? 'Ti' : widget.prefs.name)
        // 🕌 Kundërshtari nuk quhet «Kompjuteri»: emri i jep pajisjes rolin e
        // një vetjeje që luan. Ajo vetëm zbaton rregullat, ndaj rreshti mban
        // atë që lojtari ka zgjedhur vërtet — shkallën e vështirësisë.
        // I njëjti ndryshim është bërë te Mat!-i.
        : AiLevel.fromNumber(widget.level).label;
  }
}
