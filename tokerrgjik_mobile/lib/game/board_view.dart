import 'dart:math';

import 'package:flutter/material.dart';
import 'package:tokerrgjik_engine/tokerrgjik_engine.dart';

import '../app/theme.dart';

/// Tabela: e vizaton dhe i kthen prapa prekjet.
///
/// Koordinatat vijnë nga motori ([pointX] / [pointY]) dhe nuk rishkruhen këtu.
/// Një tabelë e vizatuar sipas një liste të dytë numrash është loja e saktë me
/// pamje gënjeshtare — gabimi më i keq i mundshëm, sepse gjithçka duket të
/// punojë derisa lojtari prek një pikë dhe guri shfaqet diku tjetër.
class BoardView extends StatelessWidget {
  const BoardView({
    super.key,
    required this.game,
    required this.onTap,
    this.selected,
    this.highlighted = const <int>[],
    this.lastMove,
    this.removable = const <int>[],
    this.flipped = false,
  });

  final Game game;
  final ValueChanged<int> onTap;

  /// Guri i zgjedhur për zhvendosje.
  final int? selected;

  /// Pikat ku mund të shkojë guri i zgjedhur, ose ku mund të vendoset një i ri.
  final List<int> highlighted;

  /// Lëvizja e fundit, që lojtari të shohë ç'bëri kundërshtari.
  final Move? lastMove;

  /// Gurët e kundërshtarit që mund të hiqen tani.
  final List<int> removable;

  /// A shihet tabela nga ana e të ziut.
  final bool flipped;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        final double side = min(c.maxWidth, c.maxHeight);
        return SizedBox(
          width: side,
          height: side,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (TapUpDetails d) {
              final int? point = _hitTest(d.localPosition, side);
              if (point != null) onTap(point);
            },
            child: CustomPaint(
              painter: _BoardPainter(
                game: game,
                selected: selected,
                highlighted: highlighted,
                lastMove: lastMove,
                removable: removable,
                flipped: flipped,
              ),
              size: Size.square(side),
            ),
          ),
        );
      },
    );
  }

  /// Nga piksele te numri i pikës.
  ///
  /// Rrezja e prekjes është dukshëm më e madhe se guri i vizatuar: 24 pika mbi
  /// një ekran telefoni janë të vogla, dhe një prekje që bie 4 piksele larg nuk
  /// duhet të mos bëjë asgjë. Fiton pika më e afërt brenda rrezes, kështu që dy
  /// pika ngjitur nuk e "hanë" njëra-tjetrën.
  int? _hitTest(Offset p, double side) {
    final double pad = side * _padFraction;
    final double span = side - pad * 2;
    final double radius = side * 0.07;

    int? best;
    double bestDist = double.infinity;
    for (int i = 0; i < pointCount; i++) {
      final Offset c = _centre(i, pad, span, flipped);
      final double d = (c - p).distance;
      if (d < radius && d < bestDist) {
        bestDist = d;
        best = i;
      }
    }
    return best;
  }
}

const double _padFraction = 0.09;

Offset _centre(int i, double pad, double span, bool flipped) {
  final double x = flipped ? 1.0 - pointX[i] : pointX[i];
  final double y = flipped ? 1.0 - pointY[i] : pointY[i];
  return Offset(pad + x * span, pad + y * span);
}

class _BoardPainter extends CustomPainter {
  _BoardPainter({
    required this.game,
    required this.selected,
    required this.highlighted,
    required this.lastMove,
    required this.removable,
    required this.flipped,
  });

  final Game game;
  final int? selected;
  final List<int> highlighted;
  final Move? lastMove;
  final List<int> removable;
  final bool flipped;

  @override
  void paint(Canvas canvas, Size size) {
    final double side = size.width;
    final double pad = side * _padFraction;
    final double span = side - pad * 2;
    final double stone = side * 0.045;

    Offset at(int i) => _centre(i, pad, span, flipped);

    // Dërrasa.
    final Paint wood = Paint()..color = Palette.surface;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(side * 0.05)),
      wood,
    );

    // Vijat: nxirren nga dangjet, që të mos ekzistojë një listë e dytë vijash
    // që mund të mos përputhet me rregullat.
    final Paint linePaint = Paint()
      ..color = Palette.line
      ..strokeWidth = side * 0.008
      ..strokeCap = StrokeCap.round;
    for (final List<int> line in mills) {
      canvas.drawLine(at(line[0]), at(line[1]), linePaint);
      canvas.drawLine(at(line[1]), at(line[2]), linePaint);
    }

    // Pikat boshe.
    final Paint dot = Paint()..color = Palette.line;
    for (int i = 0; i < pointCount; i++) {
      if (game.board[i] == empty) {
        canvas.drawCircle(at(i), side * 0.012, dot);
      }
    }

    // Ku mund të luhet. Unaza dhe jo guri gjysmë i tejdukshëm: një gur i zbehtë
    // lexohet si "guri im është atje", dhe lojtari beson se ka luajtur.
    final Paint hint = Paint()
      ..color = Palette.accent.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = side * 0.008;
    for (final int i in highlighted) {
      canvas.drawCircle(at(i), stone * 0.72, hint);
    }

    // Lëvizja e fundit.
    if (lastMove != null) {
      final Paint trail = Paint()
        ..color = Palette.accent.withValues(alpha: 0.28)
        ..strokeWidth = side * 0.014
        ..strokeCap = StrokeCap.round;
      if (!lastMove!.isPlacement) {
        canvas.drawLine(at(lastMove!.from), at(lastMove!.to), trail);
      }
      canvas.drawCircle(
        at(lastMove!.to),
        stone * 1.35,
        Paint()
          ..color = Palette.accent.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = side * 0.007,
      );
    }

    // Dangjet e mbyllura ndriçohen: kjo është e vetmja formë që ka rëndësi në
    // lojë dhe një lojtar i ri nuk e dallon dot mes 16 vijave.
    for (final List<int> line in mills) {
      final int who = game.board[line[0]];
      if (who == empty) continue;
      if (game.board[line[1]] != who || game.board[line[2]] != who) continue;
      canvas.drawLine(
        at(line[0]),
        at(line[2]),
        Paint()
          ..color = (who == white ? Palette.stoneWhite : Palette.stoneBlack)
              .withValues(alpha: 0.5)
          ..strokeWidth = side * 0.016
          ..strokeCap = StrokeCap.round,
      );
    }

    // Gurët.
    for (int i = 0; i < pointCount; i++) {
      final int who = game.board[i];
      if (who == empty) continue;
      _drawStone(canvas, at(i), stone, who, side);
    }

    // Gurët që mund të merren.
    final Paint target = Paint()
      ..color = Palette.danger
      ..style = PaintingStyle.stroke
      ..strokeWidth = side * 0.011;
    for (final int i in removable) {
      canvas.drawCircle(at(i), stone * 1.25, target);
    }

    // Guri i zgjedhur.
    if (selected != null) {
      canvas.drawCircle(
        at(selected!),
        stone * 1.3,
        Paint()
          ..color = Palette.accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = side * 0.012,
      );
    }
  }

  void _drawStone(Canvas canvas, Offset c, double r, int who, double side) {
    final bool isWhite = who == white;
    final Color base = isWhite ? Palette.stoneWhite : Palette.stoneBlack;

    canvas.drawCircle(
      c.translate(0, side * 0.006),
      r,
      Paint()..color = Colors.black.withValues(alpha: 0.35),
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.4),
          colors: <Color>[
            Color.lerp(base, Colors.white, isWhite ? 0.55 : 0.35)!,
            base,
            Color.lerp(base, Colors.black, 0.28)!,
          ],
          stops: const <double>[0.0, 0.55, 1.0],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
  }

  @override
  bool shouldRepaint(_BoardPainter old) =>
      old.game.encode() != game.encode() ||
      old.selected != selected ||
      old.flipped != flipped ||
      old.lastMove != lastMove ||
      !_sameList(old.highlighted, highlighted) ||
      !_sameList(old.removable, removable);

  static bool _sameList(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
