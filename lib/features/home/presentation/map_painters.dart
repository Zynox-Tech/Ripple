import 'package:flutter/material.dart';

/// Painter that draws a simple grid background.
class MapGridPainter extends CustomPainter {
  final bool isDark;
  final Color primary;

  MapGridPainter({required this.isDark, required this.primary});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = isDark ? Colors.white54 : Colors.black12
      ..strokeWidth = 1.0;

    const int rows = 8;
    const int cols = 8;
    final double cellWidth = size.width / cols;
    final double cellHeight = size.height / rows;

    // vertical lines
    for (int i = 0; i <= cols; i++) {
      final x = i * cellWidth;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    // horizontal lines
    for (int i = 0; i <= rows; i++) {
      final y = i * cellHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant MapGridPainter oldDelegate) =>
      isDark != oldDelegate.isDark || primary != oldDelegate.primary;
}

/// Painter that draws a simple curved connection between two points.
class MapConnectionPainter extends CustomPainter {
  final Color primaryColor;

  MapConnectionPainter(this.primaryColor);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = primaryColor.withOpacity(0.6)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Example: draw a simple quadratic bezier from left to right.
    final Path path = Path();
    path.moveTo(size.width * 0.1, size.height * 0.2);
    path.quadraticBezierTo(
        size.width * 0.5, size.height * 0.0, size.width * 0.9, size.height * 0.2);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant MapConnectionPainter oldDelegate) =>
      primaryColor != oldDelegate.primaryColor;
}
