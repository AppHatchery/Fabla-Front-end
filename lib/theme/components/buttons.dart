import 'package:flutter/material.dart';

import '../custom_colors.dart';
import '../custom_typography.dart';

/// Custom button with elevation.
///
/// Modify the [elevation] to achieve a deeper or shallow shadow effect.
///
/// [onClick] is the callback function when the button is clicked.
///
/// [text] is the text that will be displayed.
///
/// [color] is the background color of the button.
///
/// [shadowColor] is the shadow color of the button.
///
/// [border] is the border of the button.
///
/// [isDisabled] is a boolean that determines if the button is disabled.
class CustomElevatedButton extends StatelessWidget {
  final VoidCallback? onClick;
  final String? text;
  final Color color;
  final Color shadowColor;
  final Border border;
  final double? elevation;
  final bool isDisabled;
  const CustomElevatedButton(
      {super.key,
      required this.onClick,
      required this.text,
      this.color = CustomColors.productNormal,
      this.shadowColor = CustomColors.productNormalActive,
      this.border = const Border(),
      this.elevation = 4.5,
      this.isDisabled = false});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Ink(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            border: border,
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 0,
                offset: Offset(0, elevation!),
              ),
            ],
            shape: BoxShape.rectangle,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: isDisabled
                ? null
                : () => {
                      if (onClick != null) {onClick!()}
                    },
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10.0, vertical: 14.0),
              child: Center(
                  child: Text(text.toString(),
                      style: CustomTypography()
                          .button(color: CustomColors.fillWhite))),
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom Icon button with elevation.
///
/// Modify the [elevation] to achieve a deeper or shallow shadow effect.
///
/// [onClick] is the callback function when the button is clicked.
///
/// [icon] is the icon that will be displayed.
///
/// [color] is the background color of the button.
///
/// [shadowColor] is the shadow color of the button.
///
/// [iconColor] is the color of the icon.
///
/// [border] is the border of the button.
///
/// [elevation] is the elevation of the button.
///
/// [isDisabled] is a boolean that determines if the button is disabled.
class CustomElevatedIconButton extends StatelessWidget {
  final VoidCallback? onClick;
  final IconData icon;
  final Color color;
  final Color shadowColor;
  final Color iconColor;
  final Border border;
  final double? elevation;
  final bool isDisabled;
  const CustomElevatedIconButton(
      {super.key,
      required this.onClick,
      required this.icon,
      this.color = CustomColors.productNormal,
      this.shadowColor = CustomColors.productNormalActive,
      this.iconColor = CustomColors.fillWhite,
      this.border = const Border(),
      this.elevation = 4.5,
      this.isDisabled = false});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Ink(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            border: border,
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 0,
                offset: Offset(0, elevation!),
              ),
            ],
            shape: BoxShape.rectangle,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: isDisabled
                ? null
                : () => {
                      if (onClick != null) {onClick!()}
                    },
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10.0, vertical: 14.0),
              child: Center(
                  child: Icon(
                icon,
                color: iconColor,
              )),
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom button with no elevation.
///
/// [onClick] is the callback function when the button is clicked.
///
/// [text] is the text that will be displayed.
///
/// [color] is the background color of the button.
///
/// [isDisabled] is a boolean that determines if the button is disabled.
class CustomFlatButton extends StatelessWidget {
  final VoidCallback? onClick;
  final String? text;
  final Color color;
  final bool isDisabled;
  const CustomFlatButton({
    super.key,
    required this.onClick,
    required this.text,
    this.color = CustomColors.productNormal,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Ink(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            shape: BoxShape.rectangle,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: isDisabled
                ? null
                : () => {
                      if (onClick != null) {onClick!()}
                    },
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10.0, vertical: 14.0),
              child: Center(
                  child: Text(text.toString(),
                      style: CustomTypography()
                          .button(color: CustomColors.fillWhite))),
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom Text button with no elevation.
///
/// [onClick] is the callback function when the button is clicked.
///
/// [text] is the text that will be displayed.
///
/// [isDisabled] is a boolean that determines if the button is disabled.
class CustomTextButton extends StatelessWidget {
  final VoidCallback? onClick;
  final String? text;
  final bool isDisabled;
  const CustomTextButton({
    super.key,
    required this.onClick,
    required this.text,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
        onPressed: isDisabled
            ? null
            : () => {
                  if (onClick != null) {onClick!()}
                },
        style: TextButton.styleFrom(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 18.0),
          child: Text(
            text.toString(),
            style: CustomTypography().button(color: CustomColors.productNormal),
          ),
        ));
  }
}

/// Custom Record button.
///
/// [onClick] is the callback function when the button is clicked.
///
/// [text] is the text that will be displayed.
class CustomRecordButton extends StatelessWidget {
  final VoidCallback? onClick;
  final String? text;
  const CustomRecordButton(
      {super.key, required this.onClick, required this.text});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Ink(
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 255, 255, 255),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade400,
                blurRadius: 0,
                offset: const Offset(0, 4.5),
              ),
            ],
            shape: BoxShape.rectangle,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => {
              if (onClick != null) {onClick!()}
            },
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10.0, vertical: 18.0),
              child: Center(
                  child: Text(
                text.toString(),
                style: CustomTypography()
                    .button(color: CustomColors.productNormalActive),
              )),
            ),
          ),
        ),
      ),
    );
  }
}
