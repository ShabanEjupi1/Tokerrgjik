import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tokerrgjik_engine/tokerrgjik_engine.dart';

import 'app/ads.dart';
import 'app/prefs.dart';
import 'app/theme.dart';
import 'game/local_game_page.dart';
import 'game/sfida.dart';
import 'online/lobby_page.dart';
import 'rules_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.prefs});

  final Prefs prefs;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    final ({String moves, int level, int human})? saved = widget.prefs.savedGame;

    return Scaffold(
      // 🔑 Banderola rri VETËM këtu, te menyja, dhe jashtë zonës që rrëshqet:
      // një reklamë që lëviz bashkë me përmbajtjen kalon nën gishtin që po
      // rrëshqet dhe prodhon klikime që lojtari nuk i deshi kurrë. Kur reklama
      // nuk është gati, `BannerSlot` kthen hapësirë zero — pra menyja nuk ka
      // asnjë vend bosh të mbajtur për diçka që mund të mos vijë.
      bottomNavigationBar: const SafeArea(child: BannerSlot()),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const _Title(),
              const SizedBox(height: 28),

              if (saved != null) ...<Widget>[
                FilledButton.icon(
                  onPressed: () => _play(
                    level: saved.level,
                    human: saved.human,
                    resume: saved.moves.split(','),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Vazhdo lojën'),
                ),
                const SizedBox(height: 12),
              ],

              // 🕌 Ikonat e kësaj menyje nuk kanë qenie të gjalla dhe as sende
              // që zëvendësojnë një qenie. Historiku, që të mos kthehet asnjë
              // hap prapa:
              //   `smart_toy` (fytyrë roboti me sy e gojë) → `memory` (çip) →
              //   sot vetëm numri i lojtarëve.
              //   `people` (dy bysta njerëzish) → `swap_horiz` → «2».
              // Modaliteti nuk quhet më «Kundër kompjuterit»: emri e ngrinte
              // pajisjen në kundërshtar, kurse ajo vetëm zbaton rregullat.
              // I njëjti ndryshim është bërë te Mat!-i — mbaji të dyja njësoj.
              FilledButton.icon(
                onPressed: () => unawaited(_chooseLevel()),
                icon: const Icon(Icons.looks_one_rounded),
                label: const Text('Luaj vetëm'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _play(level: 0, human: white),
                icon: const Icon(Icons.looks_two_rounded),
                label: const Text('Dy lojtarë, një telefon'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => unawaited(Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => LobbyPage(prefs: widget.prefs),
                  ),
                )),
                icon: const Icon(Icons.public),
                label: const Text('Luaj online'),
              ),
              const SizedBox(height: 12),
              // Sfida e ditës: e njëjta për këdo, pa asnjë kërkesë rrjeti.
              // Etiketa e mban serinë, sepse pikërisht seria është arsyeja
              // pse dikush e hap aplikacionin nesër.
              OutlinedButton.icon(
                onPressed: _luajSfiden,
                icon: const Icon(Icons.today_outlined),
                label: Text(
                  widget.prefs.sfidaEBere(Sfida.dataESotme())
                      ? 'Sfida e ditës — e bërë ✓'
                      : widget.prefs.sfidaSeria > 0
                          ? 'Sfida e ditës · seri ${widget.prefs.sfidaSeria}'
                          : 'Sfida e ditës',
                ),
              ),

              const SizedBox(height: 32),
              _Stats(prefs: widget.prefs),
              const SizedBox(height: 20),

              TextButton.icon(
                onPressed: () => unawaited(Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const RulesPage()),
                )),
                icon: const Icon(Icons.menu_book_outlined),
                label: const Text('Si luhet'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _chooseLevel() async {
    final int? level = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Palette.surface,
      showDragHandle: true,
      builder: (BuildContext context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text('Sa i fortë ta duash?',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
            ),
            for (final AiLevel l in AiLevel.values)
              ListTile(
                title: Text(l.label),
                trailing: l.number == widget.prefs.level
                    ? const Icon(Icons.check, color: Palette.accent)
                    : null,
                onTap: () => Navigator.of(context).pop(l.number),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (level == null) return;
    await widget.prefs.setLevel(level);

    if (!mounted) return;
    // Ngjyra ndërrohet pa rregull. E bardha luan e para dhe ajo epërsi nuk
    // duhet të jetë gjithmonë e lojtarit — ndryshe niveli më i lartë ndihet më
    // i lehtë se ç'është.
    final int human =
        DateTime.now().millisecondsSinceEpoch.isEven ? white : black;
    _play(level: level, human: human);
  }

  /// Sfida e ditës. Niveli dhe ngjyra dalin nga data, ndaj janë të njëjta për
  /// këdo — dhe një ditë e fituar nuk luhet dy herë.
  void _luajSfiden() {
    final String sot = Sfida.dataESotme();
    if (widget.prefs.sfidaEBere(sot)) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(
            content: Text('Sfida e sotme u fitua. Kthehu nesër!')));
      return;
    }
    final Sfida s = Sfida.eDites(sot);
    _play(level: s.niveli, human: s.ngjyra, sfidaData: sot);
  }

  void _play({
    required int level,
    required int human,
    List<String> resume = const <String>[],
    String? sfidaData,
  }) {
    unawaited(Navigator.of(context)
        .push(MaterialPageRoute<void>(
          builder: (_) => LocalGamePage(
            prefs: widget.prefs,
            level: level,
            humanColour: human,
            resumeMoves: resume,
            sfidaData: sfidaData,
          ),
        ))
        .then((_) {
      if (mounted) setState(() {});
    }));
  }
}

class _Title extends StatelessWidget {
  const _Title();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        SizedBox(
          height: 150,
          child: CustomPaint(
            painter: _MiniBoardPainter(),
            size: const Size.square(150),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Tokërrgjik',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 40, fontWeight: FontWeight.w800, letterSpacing: -0.5),
        ),
        const Text(
          'Loja tradicionale shqiptare',
          textAlign: TextAlign.center,
          style: TextStyle(color: Palette.textDim, fontSize: 15),
        ),
      ],
    );
  }
}

/// Tabela e vogël e ballinës. Vizatohet nga i njëjti burim si tabela e lojës —
/// pikat dhe vijat vijnë nga motori, jo nga një skicë e dytë.
class _MiniBoardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width;
    Offset at(int i) => Offset(s * 0.08 + pointX[i] * s * 0.84,
        s * 0.08 + pointY[i] * s * 0.84);

    final Paint line = Paint()
      ..color = Palette.line
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (final List<int> m in mills) {
      canvas.drawLine(at(m[0]), at(m[1]), line);
      canvas.drawLine(at(m[1]), at(m[2]), line);
    }
    for (int i = 0; i < pointCount; i++) {
      canvas.drawCircle(at(i), 3, Paint()..color = Palette.line);
    }
    // Një dang i mbyllur, si ftesë.
    for (final int i in <int>[0, 1, 2]) {
      canvas.drawCircle(at(i), 7, Paint()..color = Palette.stoneWhite);
    }
    for (final int i in <int>[8, 9, 16]) {
      canvas.drawCircle(at(i), 7, Paint()..color = Palette.stoneBlack);
    }
    canvas.drawLine(
      at(0),
      at(2),
      Paint()
        ..color = Palette.stoneWhite.withValues(alpha: 0.55)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_MiniBoardPainter oldDelegate) => false;
}

class _Stats extends StatelessWidget {
  const _Stats({required this.prefs});

  final Prefs prefs;

  @override
  Widget build(BuildContext context) {
    final int total = prefs.wins + prefs.losses + prefs.draws;
    if (total == 0) return const SizedBox.shrink();

    Widget cell(String label, int value, Color colour) => Expanded(
          child: Column(
            children: <Widget>[
              Text('$value',
                  style: TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w700, color: colour)),
              Text(label,
                  style: const TextStyle(color: Palette.textDim, fontSize: 13)),
            ],
          ),
        );

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Row(
          children: <Widget>[
            cell('Fitore', prefs.wins, Palette.good),
            cell('Humbje', prefs.losses, Palette.danger),
            cell('Barazime', prefs.draws, Palette.textDim),
            // Seria e sfidës rri këtu e jo te butoni sepse ajo është arritje,
            // jo veprim. Fshihet kur është zero, që kutia të mos mësojë
            // askënd me një «0» të përhershëm.
            if (prefs.sfidaSeria > 0)
              cell('Seri ditore', prefs.sfidaSeria, Palette.accent),
          ],
        ),
      ),
    );
  }
}
