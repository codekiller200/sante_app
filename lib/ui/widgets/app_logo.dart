import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 40,
    this.borderRadius = 12,
    this.backgroundColor,
    this.padding = const EdgeInsets.all(6),
  });

  final double size;
  final double borderRadius;
  final Color? backgroundColor;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Image.asset(
        'assets/images/MediRemind_logo.png',
        fit: BoxFit.contain,
      ),
    );
  }
}
