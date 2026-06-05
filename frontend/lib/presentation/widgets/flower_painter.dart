import 'dart:math' as math;
import 'package:flutter/material.dart';

class IrisFlowerWidget extends StatefulWidget {
  final String speciesKey; // "setosa", "versicolor", "virginica"
  final double size;

  const IrisFlowerWidget({
    super.key,
    required this.speciesKey,
    this.size = 200.0,
  });

  @override
  State<IrisFlowerWidget> createState() => _IrisFlowerWidgetState();
}

class _IrisFlowerWidgetState extends State<IrisFlowerWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: FlowerPainter(
            speciesKey: widget.speciesKey,
            animationValue: _controller.value,
          ),
        );
      },
    );
  }
}

class FlowerPainter extends CustomPainter {
  final String speciesKey;
  final double animationValue;

  FlowerPainter({
    required this.speciesKey,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 1.4);
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Swaying animation offset
    final sway = math.sin(animationValue * 2 * math.pi) * 4.0;
    
    // Draw stem
    final stemPaint = Paint()
      ..color = const Color(0xFF10B981) // Emerald stem
      ..strokeWidth = size.width * 0.03
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final stemPath = Path()
      ..moveTo(center.dx, center.dy)
      ..cubicTo(
        center.dx + sway * 0.5,
        center.dy + size.height * 0.1,
        center.dx - sway * 0.5,
        center.dy + size.height * 0.2,
        center.dx,
        size.height,
      );
    canvas.drawPath(stemPath, stemPaint);

    // Set colors & scaling based on species
    Color petalColor;
    Color sepalColor;
    double petalScale;
    double sepalScale;
    
    switch (speciesKey.toLowerCase()) {
      case 'setosa':
        petalColor = const Color(0xFF818CF8); // Soft Light Blue
        sepalColor = const Color(0xFF4F46E5); // Indigo
        petalScale = 0.4;  // Setosa has tiny erect petals
        sepalScale = 1.0;  // Large drooping sepals
        break;
      case 'versicolor':
        petalColor = const Color(0xFFA78BFA); // Medium Lavender
        sepalColor = const Color(0xFF7C3AED); // Medium Violet
        petalScale = 0.75; // Balanced proportions
        sepalScale = 0.85;
        break;
      case 'virginica':
      default:
        petalColor = const Color(0xFFC084FC); // Vibrant Purple
        sepalColor = const Color(0xFF6B21A8); // Deep Plum
        petalScale = 1.1;  // Large petals
        sepalScale = 1.1;  // Large sepals
        break;
    }

    // Draw Leaves
    final leafPaint = Paint()
      ..color = const Color(0xFF059669)
      ..style = PaintingStyle.fill;
    
    // Left leaf
    final leftLeaf = Path()
      ..moveTo(center.dx, center.dy + size.height * 0.15)
      ..quadraticBezierTo(
        center.dx - size.width * 0.3 + sway,
        center.dy + size.height * 0.05,
        center.dx - size.width * 0.4 + sway,
        center.dy + size.height * 0.1,
      )
      ..quadraticBezierTo(
        center.dx - size.width * 0.2 + sway,
        center.dy + size.height * 0.2,
        center.dx,
        center.dy + size.height * 0.22,
      );
    canvas.drawPath(leftLeaf, leafPaint);

    // Right leaf
    final rightLeaf = Path()
      ..moveTo(center.dx, center.dy + size.height * 0.18)
      ..quadraticBezierTo(
        center.dx + size.width * 0.3 + sway,
        center.dy + size.height * 0.08,
        center.dx + size.width * 0.4 + sway,
        center.dy + size.height * 0.13,
      )
      ..quadraticBezierTo(
        center.dx + size.width * 0.2 + sway,
        center.dy + size.height * 0.24,
        center.dx,
        center.dy + size.height * 0.25,
      );
    canvas.drawPath(rightLeaf, leafPaint);

    // 1. Draw 3 outer drooping Sepals (rotated by 0, 120, 240 degrees)
    for (int i = 0; i < 3; i++) {
      final angle = (i * 120 * math.pi / 180) + (sway * 0.005);
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);
      
      final sepalPath = Path();
      // Draw drooping petal-like sepal pointing down
      sepalPath.moveTo(0, 0);
      sepalPath.cubicTo(
        -size.width * 0.15 * sepalScale,
        size.height * 0.15 * sepalScale,
        -size.width * 0.2 * sepalScale,
        size.height * 0.35 * sepalScale,
        0,
        size.height * 0.45 * sepalScale,
      );
      sepalPath.cubicTo(
        size.width * 0.2 * sepalScale,
        size.height * 0.35 * sepalScale,
        size.width * 0.15 * sepalScale,
        size.height * 0.15 * sepalScale,
        0,
        0,
      );
      
      paint.color = sepalColor;
      canvas.drawPath(sepalPath, paint);

      // Yellow/white signal guide in center of sepal (natively helps attract bees!)
      final guidePaint = Paint()
        ..color = const Color(0xFFFBBF24) // Yellow guide
        ..style = PaintingStyle.fill;
      
      final guidePath = Path()
        ..moveTo(0, size.height * 0.05 * sepalScale)
        ..cubicTo(
          -size.width * 0.05 * sepalScale,
          size.height * 0.15 * sepalScale,
          -size.width * 0.03 * sepalScale,
          size.height * 0.25 * sepalScale,
          0,
          size.height * 0.32 * sepalScale,
        )
        ..cubicTo(
          size.width * 0.03 * sepalScale,
          size.height * 0.25 * sepalScale,
          size.width * 0.05 * sepalScale,
          size.height * 0.15 * sepalScale,
          0,
          size.height * 0.05 * sepalScale,
        );
      canvas.drawPath(guidePath, guidePaint);

      // White overlay details for detail contrast
      final whitePaint = Paint()
        ..color = Colors.white.withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawPath(guidePath, whitePaint);

      canvas.restore();
    }

    // 2. Draw 3 inner erect Petals (rotated by 60, 180, 300 degrees)
    for (int i = 0; i < 3; i++) {
      final angle = ((i * 120 + 60) * math.pi / 180) + (sway * 0.005);
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);
      
      final petalPath = Path();
      // Draw erect petal pointing up
      petalPath.moveTo(0, 0);
      petalPath.cubicTo(
        -size.width * 0.1 * petalScale,
        -size.height * 0.12 * petalScale,
        -size.width * 0.12 * petalScale,
        -size.height * 0.25 * petalScale,
        0,
        -size.height * 0.35 * petalScale,
      );
      petalPath.cubicTo(
        size.width * 0.12 * petalScale,
        -size.height * 0.25 * petalScale,
        size.width * 0.1 * petalScale,
        -size.height * 0.12 * petalScale,
        0,
        0,
      );
      
      paint.color = petalColor;
      canvas.drawPath(petalPath, paint);

      // Veins in petal
      final veinPaint = Paint()
        ..color = sepalColor.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      
      canvas.drawLine(
        const Offset(0, 0),
        Offset(0, -size.height * 0.3 * petalScale),
        veinPaint,
      );
      
      canvas.restore();
    }

    // Draw Pistil/Center Bud
    final budPaint = Paint()
      ..color = const Color(0xFFFCD34D) // Honey Yellow
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, size.width * 0.04, budPaint);

    final budBorderPaint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, size.width * 0.04, budBorderPaint);
  }

  @override
  bool shouldRepaint(covariant FlowerPainter oldDelegate) {
    return oldDelegate.speciesKey != speciesKey ||
        oldDelegate.animationValue != animationValue;
  }
}
