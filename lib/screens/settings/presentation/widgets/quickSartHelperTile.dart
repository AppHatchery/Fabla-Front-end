import 'package:flutter/material.dart';

import '../../../../core/usecases/font_scaler_detector_and_adjuster.dart';
import '../../../../theme/custom_colors.dart';
import '../../../../theme/custom_typography.dart';

class Tile extends StatelessWidget {
  const Tile({
    super.key,
    required this.title,
    required this.description,
    required this.imagePath,
    this.onTap,
  });

  final String title;
  final String description;
  final String imagePath;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textScaler = getAdaptiveTextScaler(context);
    final typography = CustomTypography();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
        decoration: ShapeDecoration(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(
              color: CustomColors.productBorderNormal,
              width: 1,
            ),
          ),
          color: Colors.white,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: 14,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: Image.asset(imagePath),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 3,
                children: [
                  Text(
                    title,
                    textScaler: textScaler,
                    style: typography.bodyLarge(
                      color: CustomColors.textNormalContent,
                      weight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    description,
                    textScaler: textScaler,
                    style: typography.bodyMedium(
                      color: CustomColors.textTertiaryContent,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: textScaler.scale(24),
              color: CustomColors.midGrey,
            ),
          ],
        ),
      ),
    );
  }
}
