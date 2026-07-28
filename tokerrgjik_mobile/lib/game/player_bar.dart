import 'package:flutter/material.dart';
import 'package:tokerrgjik_engine/tokerrgjik_engine.dart';

import '../app/theme.dart';

/// Rreshti i një lojtari: emri, gurët në dorë dhe ata mbi tabelë.
///
/// Gurët në dorë tregohen si gurë e jo si numër, sepse gjatë vendosjes kjo
/// është e gjithë loja: sa më ka mbetur për të vënë, dhe sa i ka ai.
class PlayerBar extends StatelessWidget {
  const PlayerBar({
    super.key,
    required this.game,
    required this.colour,
    required this.name,
    required this.active,
    this.thinking = false,
    this.subtitle,
  });

  final Game game;
  final int colour;
  final String name;
  final bool active;
  final bool thinking;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final Color stone =
        colour == white ? Palette.stoneWhite : Palette.stoneBlack;
    final int inHand = game.inHand(colour);
    final int onBoard = game.onBoard(colour);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: active ? Palette.surfaceHigh : Palette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: active ? Palette.accent : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(color: stone, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 16),
                ),
                if (subtitle != null)
                  Text(subtitle!,
                      style: const TextStyle(
                          color: Palette.textDim, fontSize: 12)),
              ],
            ),
          ),
          if (thinking)
            const Padding(
              padding: EdgeInsets.only(right: 10),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          if (inHand > 0) ...<Widget>[
            _Stones(count: inHand, colour: stone),
            const SizedBox(width: 10),
          ],
          Text(
            '$onBoard',
            style: const TextStyle(
                color: Palette.textDim,
                fontSize: 15,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _Stones extends StatelessWidget {
  const _Stones({required this.count, required this.colour});

  final int count;
  final Color colour;

  @override
  Widget build(BuildContext context) {
    // Gurët mbivendosen: nëntë rrathë me hapësirë të plotë nuk hyjnë në ekranin
    // e një telefoni të ngushtë, dhe një numër i vetëm nuk lexohet me bisht të
    // syrit gjatë lojës.
    return SizedBox(
      width: 10.0 * count + 6,
      height: 16,
      child: Stack(
        children: <Widget>[
          for (int i = 0; i < count; i++)
            Positioned(
              left: i * 10.0,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: colour,
                  shape: BoxShape.circle,
                  border: Border.all(color: Palette.surface, width: 1),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
