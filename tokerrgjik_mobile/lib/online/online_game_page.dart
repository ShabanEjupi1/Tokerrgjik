import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tokerrgjik_engine/tokerrgjik_engine.dart';

import '../app/theme.dart';
import '../game/board_view.dart';
import '../game/player_bar.dart';
import '../game/turn.dart';
import 'api.dart';
import 'report_sheet.dart';

/// Një ndeshje online.
///
/// Tabela vizatohet nga gjendja e SERVERIT, gjithmonë. Lëvizja e lojtarit
/// zbatohet menjëherë vendas që prekja të ndihet e çastit, por çdo përgjigje e
/// serverit e mbishkruan atë pa pyetur: nëse të dyja nuk pajtohen, i drejti
/// është serveri. Kjo është arsyeja pse aplikacioni nuk mban "gjendjen e vet
/// të vërtetë" — një lojë online me dy të vërteta prishet në heshtje dhe
/// zgjidhet vetëm duke i dalë të dy lojtarët.
class OnlineGamePage extends StatefulWidget {
  const OnlineGamePage({
    super.key,
    required this.api,
    required this.initial,
  });

  final Api api;
  final Map<String, dynamic> initial;

  @override
  State<OnlineGamePage> createState() => _OnlineGamePageState();
}

class _OnlineGamePageState extends State<OnlineGamePage> {
  late Map<String, dynamic> _view;
  late Game _game;
  late TurnBuilder _turn;
  StreamSubscription<Map<String, dynamic>>? _sub;
  Move? _lastMove;
  bool _sending = false;
  bool _resultShown = false;
  String? _error;

  String get _matchId => _view['id'] as String;
  String? get _myColour => _view['ngjyraIme'] as String?;
  bool get _waitingForOpponent => _view['iziu'] == null;

  bool get _myTurn {
    if (_myColour == null || _waitingForOpponent) return false;
    final int mine = _myColour == 'white' ? white : black;
    return _game.toPlay == mine && !_game.isOver;
  }

  @override
  void initState() {
    super.initState();
    _apply(widget.initial);
    _sub = widget.api.watch(_matchId).listen(
      (Map<String, dynamic> v) {
        // Ngjyra vjen vetëm te përgjigjet e drejtpërdrejta: rrjedha është e
        // përbashkët për të dy lojtarët dhe s'ka këndvështrim. Pa këtë kujdes,
        // ngjarja e parë do t'ia fshinte lojtarit ngjyrën e vet dhe tabela do
        // të bëhej vetëm për shikim.
        _apply(<String, dynamic>{...v, 'ngjyraIme': _myColour});
      },
      onError: (Object e) {
        if (mounted) setState(() => _error = 'Lidhja u ndërpre.');
      },
    );
  }

  @override
  void dispose() {
    final StreamSubscription<Map<String, dynamic>>? sub = _sub;
    if (sub != null) unawaited(sub.cancel());
    super.dispose();
  }

  void _apply(Map<String, dynamic> view) {
    final Game? decoded = Game.decode(view['gjendja'] as String? ?? '');
    if (decoded == null) return;

    // Përfundimet që tabela nuk i mban — dorëzim, kohë, përsëritje — vijnë
    // veçmas dhe vendosen mbi gjendjen e dekoduar.
    final String outcome = view['perfundimi'] as String? ?? Outcome.none.name;
    if (outcome != Outcome.none.name && !decoded.isOver) {
      decoded.finish(
        Outcome.values.firstWhere((Outcome o) => o.name == outcome,
            orElse: () => Outcome.none),
        EndReason.values.firstWhere(
            (EndReason r) => r.name == (view['arsyeja'] as String? ?? ''),
            orElse: () => EndReason.none),
      );
    }

    final List<dynamic> moves = (view['levizjet'] as List<dynamic>?) ?? <dynamic>[];
    final Move? last = moves.isEmpty ? null : Move.parse(moves.last as String);

    if (!mounted) {
      _view = view;
      _game = decoded;
      _turn = TurnBuilder(decoded);
      _lastMove = last;
      return;
    }

    setState(() {
      _view = view;
      _game = decoded;
      _turn = TurnBuilder(decoded);
      _lastMove = last;
      _error = null;
    });
    if (_game.isOver) _showResult();
  }

  Future<void> _onTap(int point) async {
    if (_sending || !_myTurn) return;
    final Move? move = _turn.tap(point);
    if (move == null) {
      setState(() {});
      return;
    }

    // Zbatimi vendas i parë: pa këtë, çdo prekje pret një udhëtim rrjeti dhe
    // loja ndihet e prishur edhe kur nuk është.
    if (!_game.apply(move)) return;
    unawaited(HapticFeedback.selectionClick());
    setState(() {
      _lastMove = move;
      _sending = true;
    });

    try {
      final Map<String, dynamic> r =
          await widget.api.play(_matchId, move.toString());
      _apply(<String, dynamic>{
        ...(r['ndeshja'] as Map<String, dynamic>),
        'ngjyraIme': _myColour,
      });
    } on ApiError catch (e) {
      // Serveri e refuzoi: gjendja e tij është e vërteta, dhe ajo vjen prapa.
      setState(() => _error = e.message);
      try {
        final Map<String, dynamic> r = await widget.api.match(_matchId);
        _apply(<String, dynamic>{
          ...(r['ndeshja'] as Map<String, dynamic>),
          'ngjyraIme': _myColour,
        });
      } on Object {
        // Rrjedha do ta korrigjojë vetë.
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _resign() async {
    final bool? sure = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Të dorëzohesh?'),
        content: const Text('Ndeshja mbaron dhe pikët shkojnë te kundërshtari.'),
        actions: <Widget>[
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Jo')),
          FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Po, dorëzohem')),
        ],
      ),
    );
    if (!(sure ?? false)) return;
    try {
      final Map<String, dynamic> r = await widget.api.resign(_matchId);
      _apply(<String, dynamic>{
        ...(r['ndeshja'] as Map<String, dynamic>),
        'ngjyraIme': _myColour,
      });
    } on ApiError catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  void _showResult() {
    if (_resultShown) return;
    _resultShown = true;

    final bool drew = _game.outcome == Outcome.draw;
    final bool won = (_game.outcome == Outcome.whiteWins && _myColour == 'white') ||
        (_game.outcome == Outcome.blackWins && _myColour == 'black');

    final Map<String, dynamic> before =
        (_view['eloPara'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final Map<String, dynamic> after =
        (_view['eloPas'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final String key = _myColour == 'white' ? 'w' : 'b';
    final int delta =
        ((after[key] as num?)?.toInt() ?? 0) - ((before[key] as num?)?.toInt() ?? 0);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => AlertDialog(
          title: Text(drew ? 'Barazim' : (won ? 'Fitove!' : 'Humbe')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(outcomeText(_game)),
              if (delta != 0) ...<Widget>[
                const SizedBox(height: 12),
                Text(
                  '${delta > 0 ? '+' : ''}$delta pikë',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: delta > 0 ? Palette.good : Palette.danger,
                  ),
                ),
              ],
            ],
          ),
          actions: <Widget>[
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Në rregull'),
            ),
          ],
        ),
      );
    });
  }

  /// Raportimi i kundërshtarit. Një lojtar i fshirë s'ka kë të raportojë:
  /// tombstone-i nuk është llogari dhe emri i tij nuk është i askujt.
  Future<void> _reportOpponent(Map<String, dynamic>? opponent) async {
    final String id = '${opponent?['id'] ?? ''}';
    if (id.isEmpty || (opponent?['name'] as String?) == 'Lojtar i fshirë') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('S\'ka kë të raportosh këtu.')),
      );
      return;
    }
    await showReportSheet(
      context: context,
      api: widget.api,
      targetId: id,
      targetName: opponent?['name'] as String? ?? 'Kundërshtari',
    );
  }

  @override
  Widget build(BuildContext context) {
    _turn.game = _game;
    final bool flipped = _myColour == 'black';
    final Map<String, dynamic>? whitePlayer =
        _view['ibardhi'] as Map<String, dynamic>?;
    final Map<String, dynamic>? blackPlayer =
        _view['iziu'] as Map<String, dynamic>?;

    if (_waitingForOpponent) return _waitingRoom();

    Widget bar(bool top) {
      final bool isWhite = top ? flipped : !flipped;
      final Map<String, dynamic>? p = isWhite ? whitePlayer : blackPlayer;
      return PlayerBar(
        game: _game,
        colour: isWhite ? white : black,
        name: p?['name'] as String? ?? '—',
        subtitle: p == null ? null : '${p['elo']} pikë',
        active: _game.toPlay == (isWhite ? white : black) && !_game.isOver,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Online'),
        actions: <Widget>[
          // Emri i kundërshtarit shihet pikërisht këtu, ndaj këtu rri edhe
          // rruga e raportimit që Google Play e kërkon për UGC-në.
          IconButton(
            tooltip: 'Raporto kundërshtarin',
            icon: const Icon(Icons.report_outlined),
            onPressed: () => unawaited(_reportOpponent(
                _myColour == 'white' ? blackPlayer : whitePlayer)),
          ),
          if (!_game.isOver)
            IconButton(
              tooltip: 'Dorëzohu',
              icon: const Icon(Icons.flag_outlined),
              onPressed: _resign,
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: <Widget>[
              bar(true),
              Expanded(
                child: Center(
                  child: BoardView(
                    game: _game,
                    onTap: (int p) => unawaited(_onTap(p)),
                    selected: _turn.selected,
                    highlighted: _myTurn ? _turn.highlights : const <int>[],
                    removable: _myTurn ? _turn.removalTargets : const <int>[],
                    lastMove: _lastMove,
                    flipped: flipped,
                  ),
                ),
              ),
              bar(false),
              const SizedBox(height: 12),
              Text(
                _error ?? turnHint(_game, _turn, youAre: _myColour),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _error == null ? Palette.textDim : Palette.danger,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _waitingRoom() {
    final String code = _view['kodi'] as String? ?? '????';
    return Scaffold(
      appBar: AppBar(title: const Text('Dhomë private')),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text('Jepja këtë kod shokut tënd',
                    style: TextStyle(color: Palette.textDim, fontSize: 16)),
                const SizedBox(height: 20),
                SelectableText(
                  code,
                  style: const TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 10,
                    color: Palette.accent,
                  ),
                ),
                const SizedBox(height: 28),
                OutlinedButton.icon(
                  onPressed: () {
                    unawaited(Clipboard.setData(ClipboardData(text: code)));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Kodi u kopjua')),
                    );
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('Kopjo kodin'),
                ),
                const SizedBox(height: 32),
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                const Text('Duke pritur…',
                    style: TextStyle(color: Palette.textDim)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
