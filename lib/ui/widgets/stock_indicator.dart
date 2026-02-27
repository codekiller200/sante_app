import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/medicament.dart';

class StockIndicator extends StatelessWidget {
  final Medicament medicament;
  const StockIndicator({super.key, required this.medicament});

  Color get _couleur {
    final j = medicament.joursRestants;
    if (j <= 3) return AppColors.red;
    if (j <= 7) return AppColors.orange;
    return AppColors.green;
  }

  @override
  Widget build(BuildContext context) {
    final jours = medicament.joursRestants;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${jours}j',
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w700, color: _couleur),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 48,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: (jours / 30).clamp(0.0, 1.0),
              minHeight: 5,
              backgroundColor: AppColors.gray200,
              valueColor: AlwaysStoppedAnimation(_couleur),
            ),
          ),
        ),
      ],
    );
  }
}
