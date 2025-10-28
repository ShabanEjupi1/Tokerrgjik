import 'package:flutter/material.dart';

/// Custom 3D-style joystick icon widget
class JoystickIcon extends StatelessWidget {
  final double size;
  final Color color;

  const JoystickIcon({
    super.key,
    this.size = 48,
    this.color = const Color(0xFF667eea),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Shadow/base
          Positioned(
            left: size * 0.1,
            top: size * 0.15,
            child: Container(
              width: size * 0.8,
              height: size * 0.7,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(size * 0.15),
              ),
            ),
          ),
          // Main joystick body
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              width: size * 0.8,
              height: size * 0.65,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withOpacity(0.8),
                    color,
                    color.withOpacity(0.6),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
                borderRadius: BorderRadius.circular(size * 0.15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: size * 0.1,
                    offset: Offset(size * 0.05, size * 0.05),
                  ),
                ],
              ),
            ),
          ),
          // D-pad cross (left)
          Positioned(
            left: size * 0.08,
            top: size * 0.2,
            child: Container(
              width: size * 0.25,
              height: size * 0.25,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                shape: BoxShape.circle,
              ),
              child: Stack(
                children: [
                  // Horizontal bar
                  Positioned(
                    left: 0,
                    top: size * 0.09,
                    child: Container(
                      width: size * 0.25,
                      height: size * 0.07,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(size * 0.02),
                      ),
                    ),
                  ),
                  // Vertical bar
                  Positioned(
                    left: size * 0.09,
                    top: 0,
                    child: Container(
                      width: size * 0.07,
                      height: size * 0.25,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(size * 0.02),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Buttons (right) - A button
          Positioned(
            right: size * 0.08,
            top: size * 0.15,
            child: Container(
              width: size * 0.15,
              height: size * 0.15,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Colors.red.shade300,
                    Colors.red.shade600,
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    blurRadius: size * 0.05,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'A',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: size * 0.10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          // B button
          Positioned(
            right: size * 0.05,
            top: size * 0.32,
            child: Container(
              width: size * 0.13,
              height: size * 0.13,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Colors.yellow.shade300,
                    Colors.yellow.shade700,
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.yellow.withOpacity(0.3),
                    blurRadius: size * 0.05,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'B',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: size * 0.09,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          // Highlight for 3D effect
          Positioned(
            left: size * 0.05,
            top: size * 0.05,
            child: Container(
              width: size * 0.3,
              height: size * 0.15,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.4),
                    Colors.white.withOpacity(0.0),
                  ],
                ),
                borderRadius: BorderRadius.circular(size * 0.1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
