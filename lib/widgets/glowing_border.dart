import 'package:flutter/material.dart';

class GlowingBorder extends StatelessWidget {
  final Widget child;
  final String pokemonType;
  final double borderRadius;
  final double borderWidth;
  final bool animate;

  const GlowingBorder({
    super.key,
    required this.child,
    required this.pokemonType,
    this.borderRadius = 16.0,
    this.borderWidth = 2.0,
    this.animate = true,
  });

  Color _getGlowColor() {
    switch (pokemonType.toLowerCase()) {
      case 'fire':
        return Colors.orangeAccent.shade700;
      case 'water':
        return Colors.blueAccent.shade400;
      case 'grass':
        return Colors.greenAccent.shade400;
      case 'lightning':
        return Colors.amber.shade600;
      case 'psychic':
        return Colors.purpleAccent.shade400;
      case 'dark':
        return Colors.deepPurple.shade900;
      case 'colorless':
      default:
        return Colors.grey.shade400;
    }
  }

  @override
  Widget build(BuildContext context) {
    final glowColor = _getGlowColor();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: 0.4),
            blurRadius: 10.0,
            spreadRadius: 2.0,
          ),
          BoxShadow(
            color: glowColor.withValues(alpha: 0.2),
            blurRadius: 20.0,
            spreadRadius: 4.0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: glowColor.withValues(alpha: 0.8),
              width: borderWidth,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
