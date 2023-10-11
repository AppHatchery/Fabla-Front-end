import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

import '../../../../theme/components/buttons.dart';
import '../../../../theme/custom_colors.dart';

class AvatarBackground extends StatelessWidget {
  final List<Widget> children;
  final double height;
  final double width;
  final String image;
  final String avatarType;
  final String? animation;
  final VoidCallback onContinue;
  const AvatarBackground(
      {super.key,
      required this.children,
      required this.height,
      required this.width,
      required this.image,
      this.avatarType = "image",
      this.animation,
      required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: avatarType == "image" ? Image.asset(
                image,
                width: width,
              ) : SizedBox(
                height: height * 0.55,
                width: width,
                child: RiveAnimation.asset(
                  animation!,
                  fit: BoxFit.cover,
                ),
              )
            )),
        Positioned(
            top: height > 860 ? 130 : 100,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              width: width,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              decoration: const BoxDecoration(
                  color: CustomColors.fillWhite,
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: SizedBox(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: children,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: CustomElevatedButton(
                        onClick: () => onContinue(), text: "CONTINUE"),
                  )
                ],
              ),
            ))
      ],
    );
  }
}
