import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:rive/rive.dart' as rive;
import '../../../../theme/custom_colors.dart';

class AvatarBackground extends StatefulWidget {
  final List<Widget> children;
  final double height;
  final double width;
  final String image;
  final String avatarType;
  final String? animation;
  final double? keyboardSpace;
  final bool scrollable;
  final VoidCallback onContinue;
  const AvatarBackground(
      {super.key,
      required this.children,
      required this.height,
      required this.width,
      required this.image,
      this.keyboardSpace,
      this.avatarType = "image",
      this.animation,
      this.scrollable = true,
      required this.onContinue});

  @override
  State<AvatarBackground> createState() => _AvatarBackgroundState();
}

class _AvatarBackgroundState extends State<AvatarBackground> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
            top: 10,
            left: 0,
            right: 0,
            child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: widget.avatarType == "image"
                    ? Image.asset(
                        widget.image,
                        width: widget.width,
                      )
                    : SizedBox(
                        height: widget.height > 750
                            ? widget.height > 850
                                ? widget.height * 0.5
                                : widget.height * 0.55
                            : widget.height * 0.65,
                        width: widget.width,
                        child: rive.RiveAnimation.asset(
                          widget.animation!,
                          fit: BoxFit.fitWidth,
                        ),
                      ))),
        Positioned(
            top: widget.height > 860 ? 130 : 100,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: widget.height,
              width: widget.width,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              decoration: const BoxDecoration(
                  color: CustomColors.fillWhite,
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24))),
              child: SingleChildScrollView(
                physics: widget.scrollable
                    ? const AlwaysScrollableScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: widget.children,
                      ),
                    ),
                  ],
                ),
              ),
            ))
      ],
    );
  }
}
