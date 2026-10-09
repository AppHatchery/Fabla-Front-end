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
            child: icon == null
                ? Text(info, style: CustomTypography().bodyLarge())
                : OnboardingIconText(
                    icon: icon!,
                    text: info,
                    style: CustomTypography().bodyLarge(),
                  )),
      ],
    );
  }
}

class OnboardingIconText extends StatelessWidget {
  final Icon icon;
  final String text;
  final TextStyle style;
  final double spacing;

  const OnboardingIconText({
    super.key,
    required this.icon,
    required this.text,
    required this.style,
    this.spacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    final baseIconSize = icon.size ?? IconTheme.of(context).size ?? 24;
    final iconSize = textScaler.scale(baseIconSize);
    final fontSize =
        style.fontSize ?? DefaultTextStyle.of(context).style.fontSize;
    final scaledLineHeight =
        textScaler.scale(fontSize ?? 14) * (style.height ?? 1);
    final iconTop = (scaledLineHeight > iconSize
            ? (scaledLineHeight - iconSize) / 2
            : 0.0) +
        textScaler.scale(2);
    final textTop =
        iconSize > scaledLineHeight ? (iconSize - scaledLineHeight) / 2 : 0.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: iconSize,
          child: Padding(
            padding: EdgeInsets.only(top: iconTop),
            child: SizedBox.square(
              dimension: iconSize,
              child: FittedBox(child: icon),
            ),
          ),
        ),
        SizedBox(width: spacing),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: textTop),
            child: Text(text, style: style),
          ),
        ),
      ],
    );
  }
}
