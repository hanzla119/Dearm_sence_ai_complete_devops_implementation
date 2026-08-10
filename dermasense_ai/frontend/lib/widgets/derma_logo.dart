import 'package:flutter/material.dart';

class DermaLogo extends StatelessWidget {
  final double size;
  final Color overrideColor;

  const DermaLogo({
    super.key, 
    this.size = 150, 
    this.overrideColor = const Color(0xFF20D284),
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: overrideColor.withOpacity(0.18),
              blurRadius: 40,
              spreadRadius: 6,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size(size * 0.58, size * 0.58),
              painter: LogoPainter(color: overrideColor),
            ),
          ],
        ),
      ),
    );
  }
}

class LogoPainter extends CustomPainter {
  final Color color;

  LogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    double w = size.width;
    double h = size.height;

    // 1. Soft glowing droplet in the background
    final Paint glowPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          color.withOpacity(0.18),
          const Color(0xFF13BA71).withOpacity(0.06),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    final Path bgDroplet = Path();
    bgDroplet.moveTo(w * 0.5, h * 0.10);
    bgDroplet.cubicTo(w * 0.5, h * 0.10, w * 0.88, h * 0.42, w * 0.82, h * 0.70);
    bgDroplet.cubicTo(w * 0.77, h * 0.90, w * 0.23, h * 0.90, w * 0.18, h * 0.70);
    bgDroplet.cubicTo(w * 0.12, h * 0.42, w * 0.5, h * 0.10, w * 0.5, h * 0.10);
    bgDroplet.close();
    canvas.drawPath(bgDroplet, glowPaint);

    // 2. Elegant, thin skin protective barrier/crescent ring
    final Paint barrierPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          color.withOpacity(0.7),
          const Color(0xFF13BA71).withOpacity(0.2),
        ],
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.035
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromLTWH(w * 0.08, h * 0.08, w * 0.84, h * 0.84),
      3.14 * 0.65, // Start wrapping from bottom-left
      3.14 * 1.05, // Sweep to top-right
      false,
      barrierPaint,
    );

    // 3. Premium main leaf using primary gradient
    final Paint mainLeafPaint = Paint()
      ..shader = LinearGradient(
        colors: [color, const Color(0xFF10B981)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(w * 0.25, h * 0.25, w * 0.5, h * 0.55));

    final Path mainLeaf = Path();
    mainLeaf.moveTo(w * 0.32, h * 0.72);
    mainLeaf.cubicTo(
      w * 0.36, h * 0.45,
      w * 0.54, h * 0.26,
      w * 0.70, h * 0.25,
    );
    mainLeaf.cubicTo(
      w * 0.62, h * 0.48,
      w * 0.46, h * 0.64,
      w * 0.32, h * 0.72,
    );
    mainLeaf.close();
    canvas.drawPath(mainLeaf, mainLeafPaint);

    // 4. Smaller secondary leaf for organic symmetry
    final Paint subLeafPaint = Paint()
      ..shader = LinearGradient(
        colors: [const Color(0xFF10B981), const Color(0xFF047857)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(w * 0.4, h * 0.4, w * 0.4, h * 0.3));

    final Path subLeaf = Path();
    subLeaf.moveTo(w * 0.45, h * 0.68);
    subLeaf.cubicTo(
      w * 0.50, h * 0.52,
      w * 0.64, h * 0.42,
      w * 0.74, h * 0.43,
    );
    subLeaf.cubicTo(
      w * 0.66, h * 0.56,
      w * 0.54, h * 0.64,
      w * 0.45, h * 0.68,
    );
    subLeaf.close();
    canvas.drawPath(subLeaf, subLeafPaint);

    // 5. Delicate stem connecting the leaves
    final Paint stemPaint = Paint()
      ..shader = LinearGradient(
        colors: [color.withOpacity(0.8), const Color(0xFF13BA71).withOpacity(0.4)],
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
      ).createShader(Rect.fromLTWH(w * 0.2, h * 0.6, w * 0.4, h * 0.2))
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.03
      ..strokeCap = StrokeCap.round;

    final Path stemPath = Path();
    stemPath.moveTo(w * 0.26, h * 0.76);
    stemPath.quadraticBezierTo(w * 0.35, h * 0.73, w * 0.46, h * 0.66);
    canvas.drawPath(stemPath, stemPaint);

    // 6. Glowing skin radiance sparkles on the top right
    final Paint sparklePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF34D399), Color(0xFF10B981)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(w * 0.7, h * 0.15, w * 0.25, h * 0.25))
      ..style = PaintingStyle.fill;

    _drawSparkle(canvas, Offset(w * 0.82, h * 0.20), w * 0.18, sparklePaint);
    _drawSparkle(canvas, Offset(w * 0.90, h * 0.36), w * 0.11, sparklePaint);
  }

  void _drawSparkle(Canvas canvas, Offset center, double size, Paint paint) {
    final Path sparkle = Path();
    final double half = size / 2;
    
    sparkle.moveTo(center.dx, center.dy - half);
    sparkle.quadraticBezierTo(center.dx, center.dy, center.dx + half, center.dy);
    sparkle.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + half);
    sparkle.quadraticBezierTo(center.dx, center.dy, center.dx - half, center.dy);
    sparkle.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - half);
    
    canvas.drawPath(sparkle, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
