import 'package:flutter/material.dart';

class DroneLogo extends StatelessWidget {
  const DroneLogo({super.key, this.size = 24, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ?? Theme.of(context).colorScheme.onSurface;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DroneLogoPainter(color: resolvedColor),
      ),
    );
  }
}

class _DroneLogoPainter extends CustomPainter {
  _DroneLogoPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final c = Offset(size.width / 2, size.height / 2);

    final stroke = (s * 0.08).clamp(1.2, 3.0);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Body
    final bodyW = s * 0.28;
    final bodyH = s * 0.22;
    final bodyRect = Rect.fromCenter(center: c, width: bodyW, height: bodyH);
    final bodyRRect = RRect.fromRectAndRadius(bodyRect, Radius.circular(s * 0.06));
    canvas.drawRRect(bodyRRect, paint);

    // Arms to props
    final arm = s * 0.30;
    final propOffset = arm;
    final propR = s * 0.11;

    final props = <Offset>[
      Offset(c.dx - propOffset, c.dy - propOffset),
      Offset(c.dx + propOffset, c.dy - propOffset),
      Offset(c.dx - propOffset, c.dy + propOffset),
      Offset(c.dx + propOffset, c.dy + propOffset),
    ];

    for (final p in props) {
      canvas.drawLine(c, p, paint);
      canvas.drawCircle(p, propR, paint);
      canvas.drawCircle(p, propR * 0.35, fill);
    }

    // Small "nose" indicator so rotation is meaningful.
    final nose = Path()
      ..moveTo(c.dx, c.dy - s * 0.20)
      ..lineTo(c.dx - s * 0.06, c.dy - s * 0.10)
      ..lineTo(c.dx + s * 0.06, c.dy - s * 0.10)
      ..close();
    canvas.drawPath(nose, fill);
  }

  @override
  bool shouldRepaint(covariant _DroneLogoPainter oldDelegate) => oldDelegate.color != color;
}
