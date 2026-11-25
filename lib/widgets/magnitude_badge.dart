import 'package:flutter/material.dart';
import '../utils/formatters.dart';

/// Badge visual untuk menampilkan nilai magnitudo dengan kode warna resmi
class MagnitudeBadge extends StatelessWidget {
  final double magnitude;
  final bool isLarge;
  final String? heroTag;

  const MagnitudeBadge({
    super.key,
    required this.magnitude,
    this.isLarge = false,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final color = Formatters.getMagnitudeColor(magnitude);
    final size = isLarge ? 84.0 : 54.0;
    final fontSize = isLarge ? 28.0 : 16.0;

    Widget badgeContent = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(isLarge ? 24 : 16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: isLarge ? 12 : 6,
            offset: Offset(0, isLarge ? 4 : 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'M',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: isLarge ? 12 : 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          Text(
            magnitude > 0 ? magnitude.toStringAsFixed(1) : '-',
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              height: 1.0,
            ),
          ),
        ],
      ),
    );

    if (heroTag != null) {
      return Hero(
        tag: heroTag!,
        child: Material(
          type: MaterialType.transparency,
          child: badgeContent,
        ),
      );
    }

    return badgeContent;
  }
}
