import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tokerrgjik_engine/tokerrgjik_engine.dart';

import '../app/prefs.dart';
import '../app/theme.dart';
import 'ai_worker.dart';
import 'board_view.dart';
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
  });

  /// Niveli i kompjuterit, ose 0 për dy lojtarë në një pajisje.
  final int level;

  /// Ngjyra e njeriut kur luhet kundër kompjuterit.
  final int humanColour;

  final Prefs prefs;

  /// Lëvizjet e një loje të lënë përgjysmë.
  final List<String> resumeMoves;

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
  }

  void _showResult() {
    final bool drew = _game.outcome == Outcome.draw;
    final bool humanWon = widget.vsComputer &&
        ((_game.outcome == Outcome.whiteWins && widget.humanColour == white) ||
            (_game.outcome == Outcome.blackWins && widget.humanColour == black));

    showDialog<void>(
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
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Dil'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _game = Game();
                _turn = TurnBuilder(_game);
                _lastMove = null;
                _resultRecorded = false;
              });
              unawaited(_maybeThink());
            },
            child: const Text('Përsëri'),
          ),
        ],
      ),
    );
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
                      highlighted: _humanTurn ? _turn.highlights : const <int>[],
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
        : 'Kompjuteri';
  }
}
