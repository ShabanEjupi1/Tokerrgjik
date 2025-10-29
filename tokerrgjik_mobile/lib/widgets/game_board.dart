import 'package:flutter/material.dart';
import '../models/game_model.dart';

class GameBoard extends StatelessWidget {
  final GameModel game;
  final Function(int) onPositionTap;
  final Color? boardColor;
  final Color? player1Color;
  final Color? player2Color;
  final int? hintPosition; // Position to highlight with white pulsing effect

  const GameBoard({
    super.key,
    required this.game,
    required this.onPositionTap,
    this.boardColor,
    this.player1Color,
    this.player2Color,
    this.hintPosition,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          double size = constraints.maxWidth;
          return RepaintBoundary( // Isolate repaints to improve performance
            child: Container(
              decoration: BoxDecoration(
                // Enhanced 3D wood-like board
                gradient: RadialGradient(
                center: Alignment.topLeft,
                radius: 1.5,
                colors: [
                  (boardColor ?? const Color(0xFFDAA520)).withOpacity(0.9),
                  (boardColor ?? const Color(0xFFB8860B)),
                  (boardColor ?? const Color(0xFF8B6914)),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                // Deep outer shadow
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                  spreadRadius: 2,
                ),
                // Inner highlight for 3D effect
                BoxShadow(
                  color: Colors.white.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(-5, -5),
                ),
                // Ambient shadow
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                  spreadRadius: 5,
                ),
              ],
              border: Border.all(
                color: const Color(0xFF654321),
                width: 6,
              ),
              ),
              child: Container(
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  // Inner border shadow for depth
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Board lines
                  CustomPaint(
                    size: Size(size, size),
                    painter: BoardPainter(boardColor: boardColor),
                  ),
                  // Positions and pieces
                  ...GameModel.positions.map((pos) {
                    return _buildPosition(pos, size);
                  }).toList(),
                ],
              ),
            ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPosition(Position pos, double boardSize) {
    double x = pos.x * boardSize;
    double y = pos.y * boardSize;
    int? piece = game.board[pos.id];
    bool isSelected = game.selectedPosition == pos.id;
    bool isValidMove = game.selectedPosition != null &&
        game.phase == 'moving' &&
        game.getValidMoves(game.selectedPosition!).contains(pos.id);
    bool isRemovable =
        game.phase == 'removing' && game.getRemovablePieces().contains(pos.id);
    bool isHint = hintPosition == pos.id; // Check if this is the hint position

    // Smaller pieces for better visibility and aesthetics
    double touchSize = 52.0;  // Reduced from 60
    double pieceSize = 36.0;   // Reduced from 44

    return Positioned(
      left: x - touchSize / 2,
      top: y - touchSize / 2,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque, // Prevent touch events from passing through
        onTap: () => onPositionTap(pos.id),
        child: Container(
          width: touchSize,
          height: touchSize,
          alignment: Alignment.center,
          child: isHint
              ? _PulsingHintIndicator(
                  child: _buildPositionCircle(piece, pieceSize, isSelected, isValidMove, isRemovable),
                )
              : _buildPositionCircle(piece, pieceSize, isSelected, isValidMove, isRemovable),
        ),
      ),
    );
  }

  Widget _buildPositionCircle(int? piece, double pieceSize, bool isSelected, bool isValidMove, bool isRemovable) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150), // Reduced from 200ms for snappier response
      curve: Curves.easeOut, // Better performance curve
      width: pieceSize,
      height: pieceSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: piece != null
          ? (piece == 1 
              ? (player1Color ?? const Color(0xFFFFF8DC)) // Cream color - visible on all themes
              : (player2Color ?? Colors.black87))
          : (isValidMove ? Colors.blue.withOpacity(0.3) : Colors.grey.shade300),
        border: Border.all(
          color: isSelected
              ? Colors.orange
              : isRemovable
                  ? Colors.red
                  : isValidMove
                      ? Colors.blue
                      : (piece != null 
                          ? (piece == 1 
                              ? Colors.black.withOpacity(0.9)  // Dark border for white pieces
                              : Colors.white.withOpacity(0.9)) // White border for black pieces
                          : Colors.black54),
          width: piece != null 
              ? (isSelected || isRemovable ? 5.0 : 4.5)  // Thicker border for better visibility
              : (isSelected || isRemovable ? 4 : 2),
        ),
        boxShadow: piece != null || isValidMove
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
                // 3D highlight effect
                BoxShadow(
                  color: Colors.white.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(-2, -2),
                ),
              ]
            : null,
        gradient: piece != null 
            ? RadialGradient(
                center: const Alignment(-0.3, -0.3),
                colors: [
                  // Bright highlight for 3D effect
                  piece == 1 
                      ? (player1Color ?? Colors.white).withOpacity(1.0)
                      : (player2Color ?? Colors.black87).withOpacity(1.0),
                  piece == 1 
                      ? (player1Color ?? Colors.white)
                      : (player2Color?.withOpacity(0.95) ?? Colors.black87),
                  // Darker edge for depth
                  piece == 1 
                      ? (player1Color?.withOpacity(0.75) ?? Colors.grey.shade300)
                      : (player2Color?.withOpacity(0.7) ?? Colors.black54),
                ],
                stops: const [0.0, 0.4, 1.0],
              )
            : null,
      ),
      child: isRemovable
          ? const Icon(
              Icons.close,
              color: Colors.red,
              size: 24,
            )
          : null,
    );
  }
}

// Pulsing white glow animation for hint indicator
class _PulsingHintIndicator extends StatefulWidget {
  final Widget child;
  
  const _PulsingHintIndicator({required this.child});
  
  @override
  _PulsingHintIndicatorState createState() => _PulsingHintIndicatorState();
}

class _PulsingHintIndicatorState extends State<_PulsingHintIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(_animation.value * 0.8),
                blurRadius: 20 * _animation.value,
                spreadRadius: 5 * _animation.value,
              ),
              BoxShadow(
                color: Colors.amber.withOpacity(_animation.value * 0.5),
                blurRadius: 30 * _animation.value,
                spreadRadius: 8 * _animation.value,
              ),
            ],
          ),
          child: widget.child,
        );
      },
    );
  }
}

class BoardPainter extends CustomPainter {
  final Color? boardColor;
  
  BoardPainter({this.boardColor});
  
  @override
  void paint(Canvas canvas, Size size) {
    // Enhanced 3D board lines with shadows and highlights
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.4)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    final paint = Paint()
      ..color = const Color(0xFF654321)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw three squares with 3D effect
    void drawSquareWith3D(Rect rect) {
      // Shadow
      canvas.drawRect(rect.shift(const Offset(2, 2)), shadowPaint);
      // Main line
      canvas.drawRect(rect, paint);
      // Highlight on top-left
      canvas.drawLine(
        rect.topLeft,
        rect.topRight,
        highlightPaint,
      );
      canvas.drawLine(
        rect.topLeft,
        rect.bottomLeft,
        highlightPaint,
      );
    }

    // Outer square
    drawSquareWith3D(Rect.fromLTWH(
      size.width * 0.1,
      size.height * 0.1,
      size.width * 0.8,
      size.height * 0.8,
    ));

    // Middle square
    drawSquareWith3D(Rect.fromLTWH(
      size.width * 0.25,
      size.height * 0.25,
      size.width * 0.5,
      size.height * 0.5,
    ));

    // Inner square
    drawSquareWith3D(Rect.fromLTWH(
      size.width * 0.4,
      size.height * 0.4,
      size.width * 0.2,
      size.height * 0.2,
    ));

    // Draw connecting lines with gradient for 3D effect
    void drawConnectingLine(Offset start, Offset end) {
      // Shadow
      canvas.drawLine(
        start.translate(2, 2),
        end.translate(2, 2),
        shadowPaint,
      );
      // Main line
      canvas.drawLine(start, end, paint);
      // Highlight
      canvas.drawLine(
        start.translate(-1, -1),
        end.translate(-1, -1),
        highlightPaint,
      );
    }

    // Top
    drawConnectingLine(
      Offset(size.width * 0.5, size.height * 0.1),
      Offset(size.width * 0.5, size.height * 0.4),
    );

    // Bottom
    drawConnectingLine(
      Offset(size.width * 0.5, size.height * 0.6),
      Offset(size.width * 0.5, size.height * 0.9),
    );

    // Left
    drawConnectingLine(
      Offset(size.width * 0.1, size.height * 0.5),
      Offset(size.width * 0.4, size.height * 0.5),
    );

    // Right
    drawConnectingLine(
      Offset(size.width * 0.6, size.height * 0.5),
      Offset(size.width * 0.9, size.height * 0.5),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
