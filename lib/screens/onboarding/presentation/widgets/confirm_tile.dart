import 'package:audio_diaries_flutter/theme/custom_colors.dart';
import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:flutter/material.dart';

class ConfrimTile extends StatelessWidget {
  final String title;
  final String info;
  final Icon? icon;
  const ConfrimTile(
      {super.key, required this.title, required this.info, this.icon});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: CustomTypography().titleSmall(color: Colors.white)),
        const SizedBox(
          height: 6,
        ),
        Container(
            width: width,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
                color: CustomColors.fillWhite,
                border: Border.all(
                    color: CustomColors.productBorderNormal, width: 2),
                borderRadius: BorderRadius.circular(11)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                icon != null
                    ? Padding(
                        padding: const EdgeInsets.only(right: 8.0), child: icon)
                    : const SizedBox.shrink(),
                Expanded(
                  child: Text(
                    info,
                    style: CustomTypography()
                        .bodyLarge(),
                  ),
                )
              ],
            )),
      ],
    );
  }
}
