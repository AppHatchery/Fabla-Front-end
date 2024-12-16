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
  final Border border;
  final double? elevation;
  final bool isDisabled;
  final Color? textColor;
  const CustomElevatedButton(
      {super.key,
      required this.onClick,
      required this.text,
      this.color = CustomColors.productNormal,
      this.border = const Border(),
      this.elevation = 4.5,
      this.isDisabled = false,
      this.textColor});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Ink(
          decoration: BoxDecoration(
            color: isDisabled ? CustomColors.fillDisabled : color,
            borderRadius: BorderRadius.circular(12),
            border: border,
            // boxShadow: [
            //   BoxShadow(
            //     color: shadowColor,
            //     blurRadius: 0,
            //     offset: Offset(0, elevation!),
            //   ),
            // ],
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
                      style: CustomTypography().button(
                        color: isDisabled
                            ? CustomColors.textTertiaryContent
                            : textColor ?? CustomColors.fillWhite,
                      ))),
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
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
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
  final Color textColor;
  final Color borderColor;
  const CustomFlatButton({
    super.key,
    required this.onClick,
    required this.text,
    this.color = CustomColors.productNormal,
    this.isDisabled = false,
    this.textColor = CustomColors.fillWhite,
    this.borderColor = CustomColors.productNormal,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Ink(
          decoration: BoxDecoration(
            color: isDisabled ? CustomColors.fillDisabled : color,
            borderRadius: BorderRadius.circular(12),
            shape: BoxShape.rectangle,
            border: Border.all(
                color: isDisabled ? CustomColors.fillDisabled : borderColor,
                width: 1),
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
                      style: CustomTypography().button(
                          color:
                              isDisabled ? CustomColors.greyDark : textColor))),
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
  final Color textColor;
  final bool isDisabled;
  const CustomTextButton({
    super.key,
    required this.onClick,
    required this.text,
    this.textColor = CustomColors.productNormal,
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
            style: CustomTypography().button(color: textColor),
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
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: Ink(
          decoration: BoxDecoration(
            color: CustomColors.productNormal,
            //const Color.fromARGB(255, 255, 255, 255),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white, width: 2),
            // boxShadow: [
            //   BoxShadow(
            //     color: Colors.grey.shade400,
            //     blurRadius: 0,
            //     offset: const Offset(0, 4.5),
            //   ),
            // ],
            shape: BoxShape.rectangle,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => {
              if (onClick != null) {onClick!()}
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10.0, vertical: 12.0),
              width: MediaQuery.of(context).size.width,
              child: Center(
                  child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.mic, color: CustomColors.fillWhite),
                  const SizedBox(
                    width: 8,
                  ),
                  Flexible(
                    child: Text(
                      text.toString(),
                      style: CustomTypography()
                          .button(color: CustomColors.fillWhite),
                    ),
                  ),
                ],
              )),
            ),
          ),
        ),
      ),
    );
  }
}

class CustomTextAnswerButton extends StatelessWidget {
  final VoidCallback? onClick;
  final String? text;
  const CustomTextAnswerButton(
      {super.key, required this.onClick, required this.text});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: Ink(
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 255, 255, 255),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: CustomColors.productNormal, width: 1),
            shape: BoxShape.rectangle,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => {
              if (onClick != null) {onClick!()}
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10.0, vertical: 12.0),
              width: MediaQuery.of(context).size.width,
              child: Center(
                  child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.keyboard, color: CustomColors.productNormal),
                  const SizedBox(
                    width: 8,
                  ),
                  Flexible(
                    child: Text(
                      text.toString(),
                      style: CustomTypography()
                          .button(color: CustomColors.productNormal),
                    ),
                  ),
                ],
              )),
            ),
          ),
        ),
      ),
    );
  }
}

class CustomOutlineButton extends StatelessWidget {
  final VoidCallback onClick;
  final Wrap children;
  final Color color;
  final Color backgroundColor;
  final bool? isDisabled;

  const CustomOutlineButton(
      {super.key,
      required this.onClick,
      required this.children,
      required this.color,
      required this.backgroundColor,
      this.isDisabled});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color, width: 1),
          shape: BoxShape.rectangle,
        ),
        child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: isDisabled ?? false ? null : () => onClick(),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Container(child: children),
            )),
      ),
    );
  }
}
