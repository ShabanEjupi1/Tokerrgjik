import 'dart:async';

import 'package:flutter/material.dart';

import '../app/prefs.dart';
import '../app/theme.dart';
import 'api.dart';
import 'online_game_page.dart';

/// Hyrja te loja online: emri, ndeshje e rastësishme, dhomë private, tabela.
class LobbyPage extends StatefulWidget {
  const LobbyPage({super.key, required this.prefs});

  final Prefs prefs;

  @override
  State<LobbyPage> createState() => _LobbyPageState();
}

class _LobbyPageState extends State<LobbyPage> {
  final Api _api = Api();
  final TextEditingController _codeCtrl = TextEditingController();

  Map<String, dynamic>? _player;
  String? _error;
  bool _busy = true;
  bool _queued = false;
  Timer? _queuePoll;

  @override
  void initState() {
    super.initState();
    unawaited(_boot());
  }

  @override
  void dispose() {
    _queuePoll?.cancel();
    _codeCtrl.dispose();
    _api.close();
    super.dispose();
  }

  Future<void> _boot() async {
    _api.token = widget.prefs.token;
    try {
      // Tokeni ruhet dhe ridërgohet: pa të, çdo hapje e aplikacionit do të
      // krijonte një lojtar të ri me zero pikë, dhe renditja nuk do të thoshte
      // asgjë.
      final Map<String, dynamic> p = await _api.signIn(
          widget.prefs.name.isEmpty ? 'Lojtar' : widget.prefs.name);
      await widget.prefs.setToken(_api.token!);
      if (widget.prefs.name.isEmpty) {
        await widget.prefs.setName(p['name'] as String);
      }

      final Map<String, dynamic> me = await _api.me();
      if (!mounted) return;
      setState(() {
        _player = me['lojtari'] as Map<String, dynamic>;
        _busy = false;
      });

      // Një ndeshje e nisur më parë rihapet aty ku u la — telefoni që u mbyll
      // në mes të lojës nuk duhet ta humbasë atë.
      final Map<String, dynamic>? active = me['ndeshja'] as Map<String, dynamic>?;
      if (active != null && mounted) await _open(active);
    } on ApiError catch (e) {
      if (mounted) setState(() { _error = e.message; _busy = false; });
    }
  }

  Future<void> _open(Map<String, dynamic> view) async {
    _queuePoll?.cancel();
    _queuePoll = null;
    if (mounted) setState(() => _queued = false);
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => OnlineGamePage(api: _api, initial: view),
    ));
    if (!mounted) return;
    try {
      final Map<String, dynamic> me = await _api.me();
      setState(() => _player = me['lojtari'] as Map<String, dynamic>);
    } on ApiError {
      // Tabela e pikëve mund të presë.
    }
  }

  Future<void> _findOpponent() async {
    setState(() { _busy = true; _error = null; });
    try {
      final Map<String, dynamic> r = await _api.joinQueue();
      if (!mounted) return;
      setState(() => _busy = false);

      final Map<String, dynamic>? m = r['ndeshja'] as Map<String, dynamic>?;
      if (m != null) return _open(m);

      // Në radhë. Serveri nuk mund ta thërrasë telefonin, ndaj pyetet çdo dy
      // sekonda derisa të gjendet dikush.
      setState(() => _queued = true);
      _queuePoll = Timer.periodic(const Duration(seconds: 2), (_) async {
        try {
          final Map<String, dynamic> again = await _api.joinQueue();
          final Map<String, dynamic>? found =
              again['ndeshja'] as Map<String, dynamic>?;
          if (found != null && mounted) await _open(found);
        } on ApiError {
          // Pyetja tjetër.
        }
      });
    } on ApiError catch (e) {
      if (mounted) setState(() { _error = e.message; _busy = false; });
    }
  }

  Future<void> _cancelQueue() async {
    _queuePoll?.cancel();
    _queuePoll = null;
    setState(() => _queued = false);
    try {
      await _api.leaveQueue();
    } on ApiError {
      // Radha pastrohet vetë pas dy minutash.
    }
  }

  Future<void> _createRoom() async {
    setState(() { _busy = true; _error = null; });
    try {
      final Map<String, dynamic> r = await _api.createRoom();
      if (!mounted) return;
      setState(() => _busy = false);
      await _open(r['ndeshja'] as Map<String, dynamic>);
    } on ApiError catch (e) {
      if (mounted) setState(() { _error = e.message; _busy = false; });
    }
  }

  Future<void> _joinRoom() async {
    final String code = _codeCtrl.text.trim().toUpperCase();
    if (code.length != 4) {
      setState(() => _error = 'Kodi ka katër shkronja.');
      return;
    }
    setState(() { _busy = true; _error = null; });
    try {
      final Map<String, dynamic> r = await _api.joinRoom(code);
      if (!mounted) return;
      _codeCtrl.clear();
      setState(() => _busy = false);
      await _open(r['ndeshja'] as Map<String, dynamic>);
    } on ApiError catch (e) {
      if (mounted) setState(() { _error = e.message; _busy = false; });
    }
  }

  Future<void> _editName() async {
    final TextEditingController ctrl =
        TextEditingController(text: widget.prefs.name);
    final String? name = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Emri yt'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: 18,
          decoration: const InputDecoration(hintText: 'Si të të thërrasin'),
        ),
        actions: <Widget>[
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Anulo')),
          FilledButton(
              onPressed: () => Navigator.of(context).pop(ctrl.text),
              child: const Text('Ruaj')),
        ],
      ),
    );
    ctrl.dispose();
    if (name == null || name.trim().isEmpty) return;
    await widget.prefs.setName(name);
    try {
      final Map<String, dynamic> r = await _api.rename(name);
      if (mounted) {
        setState(() => _player = r['lojtari'] as Map<String, dynamic>);
      }
    } on ApiError catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  /// Cilësimet e llogarisë. Përmban fshirjen, që Google Play e kërkon të jetë
  /// e arritshme **brenda** aplikacionit për çdo llogari të krijuar brenda tij.
  Future<void> _accountSettings() async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Llogaria'),
              subtitle: Text(widget.prefs.name.isEmpty
                  ? 'Vetëm një emër — pa email, pa fjalëkalim'
                  : '${widget.prefs.name} — pa email, pa fjalëkalim'),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Palette.danger),
              title: const Text('Fshi llogarinë',
                  style: TextStyle(color: Palette.danger)),
              subtitle: const Text(
                  'Emri dhe pikët fshihen menjëherë e nuk kthehen mbrapsht.'),
              onTap: () {
                Navigator.of(sheet).pop();
                unawaited(_confirmDelete());
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    if (!mounted) return;
    final bool ok = await showDialog<bool>(
          context: context,
          builder: (BuildContext d) => AlertDialog(
            title: const Text('Të fshihet llogaria?'),
            content: const Text(
                'Emri, pikët dhe historiku yt fshihen nga serveri dhe nuk '
                'kthehen mbrapsht.\n\n'
                'Nëse je në një ndeshje, ajo mbyllet si dorëzim.\n\n'
                'Loja kundër telefonit dhe ajo në një pajisje vazhdojnë të '
                'punojnë — ato nuk kërkojnë llogari.'),
            actions: <Widget>[
              TextButton(
                  onPressed: () => Navigator.of(d).pop(false),
                  child: const Text('Jo')),
              TextButton(
                onPressed: () => Navigator.of(d).pop(true),
                style: TextButton.styleFrom(foregroundColor: Palette.danger),
                child: const Text('Fshi'),
              ),
            ],
          ),
        ) ??
        false;
    if (!ok || !mounted) return;

    try {
      await _api.deleteAccount();
    } on ApiError catch (e) {
      if (mounted) setState(() => _error = e.message);
      return;
    }
    await widget.prefs.clearToken();
    if (!mounted) return;

    // Llogaria s'ekziston më, ndaj salla nuk ka çfarë të tregojë.
    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Llogaria u fshi.')),
    );
  }

  Future<void> _showLeaderboard() async {
    List<dynamic> rows;
    try {
      rows = await _api.leaderboard();
    } on ApiError catch (e) {
      if (mounted) setState(() => _error = e.message);
      return;
    }
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Palette.surface,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text('Tabela e pikëve',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            ),
            if (rows.isEmpty)
              const Expanded(
                child: Center(
                  child: Text('Askush s\'ka luajtur ende.',
                      style: TextStyle(color: Palette.textDim)),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: rows.length,
                  itemBuilder: (BuildContext context, int i) {
                    final Map<String, dynamic> p =
                        rows[i] as Map<String, dynamic>;
                    final bool isMe = p['id'] == _player?['id'];
                    return ListTile(
                      leading: Text('${i + 1}',
                          style: const TextStyle(
                              color: Palette.textDim,
                              fontWeight: FontWeight.w600)),
                      title: Text(p['name'] as String,
                          style: TextStyle(
                              fontWeight:
                                  isMe ? FontWeight.w800 : FontWeight.w500,
                              color: isMe ? Palette.accent : Palette.text)),
                      subtitle: Text(
                          '${p['wins']}F · ${p['losses']}H · ${p['draws']}B',
                          style: const TextStyle(color: Palette.textDim)),
                      trailing: Text('${p['elo']}',
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w700)),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Luaj online'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Tabela',
            icon: const Icon(Icons.leaderboard_outlined),
            onPressed: () => unawaited(_showLeaderboard()),
          ),
          IconButton(
            tooltip: 'Cilësimet e llogarisë',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => unawaited(_accountSettings()),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (_player != null)
                Card(
                  child: ListTile(
                    title: Text(_player!['name'] as String,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700)),
                    subtitle: Text(
                        '${_player!['elo']} pikë · '
                        '${_player!['wins']}F ${_player!['losses']}H ${_player!['draws']}B',
                        style: const TextStyle(color: Palette.textDim)),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => unawaited(_editName()),
                    ),
                  ),
                ),
              const SizedBox(height: 20),

              if (_error != null) ...<Widget>[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Palette.danger.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(_error!,
                      style: const TextStyle(color: Palette.danger)),
                ),
                const SizedBox(height: 16),
              ],

              if (_queued) ...<Widget>[
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: <Widget>[
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Duke kërkuar kundërshtar…'),
                        SizedBox(height: 6),
                        Text('Kërkohet dikush me pikë të përafërta.',
                            style: TextStyle(
                                color: Palette.textDim, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                    onPressed: () => unawaited(_cancelQueue()),
                    child: const Text('Anulo')),
              ] else ...<Widget>[
                FilledButton.icon(
                  onPressed: _busy ? null : () => unawaited(_findOpponent()),
                  icon: const Icon(Icons.public),
                  label: const Text('Kundërshtar i rastësishëm'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _busy ? null : () => unawaited(_createRoom()),
                  icon: const Icon(Icons.group_add_outlined),
                  label: const Text('Krijo dhomë për një shok'),
                ),
                const SizedBox(height: 26),
                const Text('Ke një kod dhome?',
                    style: TextStyle(color: Palette.textDim)),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: _codeCtrl,
                        textCapitalization: TextCapitalization.characters,
                        maxLength: 4,
                        decoration: const InputDecoration(
                          hintText: 'ABCD',
                          counterText: '',
                          border: OutlineInputBorder(),
                        ),
                        style: const TextStyle(
                            fontSize: 22, letterSpacing: 6, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 56,
                      child: FilledButton(
                        onPressed: _busy ? null : () => unawaited(_joinRoom()),
                        child: const Text('Hyr'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
