import 'package:flutter/material.dart';

import 'package:sante_app/core/constants/app_colors.dart';
import 'package:sante_app/data/models/medicament.dart';

class StockIndicator extends StatelessWidget {
  const StockIndicator({super.key, required this.medicament});

  final Medicament medicament;

  Color get _color {
    if (medicament.joursRestants <= 3) return AppColors.danger;
    if (medicament.joursRestants <= 7) return AppColors.warning;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '${medicament.joursRestants} j',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: _color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

