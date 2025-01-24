import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:rive/rive.dart' as rive;
import '../../../../theme/custom_colors.dart';

class AvatarBackground extends StatelessWidget {
  final List<Widget> children;
  final double height;
  final double width;
  final double foregroundHeight;
  final String image;
  final String avatarType;
  final String? animation;
  final double animationHeight;
  final double? keyboardSpace;
  final bool scrollable;
  final VoidCallback onContinue;
  final Function(rive.Artboard)? onInit;

  const AvatarBackground({
    super.key,
    required this.children,
    required this.height,
    required this.width,
    this.foregroundHeight = 0.75,
    required this.image,
    this.keyboardSpace,
    this.avatarType = "image",
    this.animation,
    this.animationHeight = 0,
    this.scrollable = true,
    required this.onContinue,
    this.onInit,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildAvatarLayer(), // Background layer
        _buildForegroundLayer(), // Foreground layer
      ],
    );
  }

  Widget _buildAvatarLayer() {
    return Positioned(
      top: 10,
      left: 0,
      right: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0.0),
        child: avatarType == "image"
            ? Image.asset(
                image,
                width: width,
              )
            : SizedBox(
                height: animationHeight,
                width: width,
                child: rive.RiveAnimation.asset(
                  animation!,
                  onInit: onInit,
                  fit: BoxFit.fitWidth,
                ),
              ),
      ),
    );
  }

  Widget _buildForegroundLayer() {
    return Positioned(
      top: animationHeight * foregroundHeight, // Simplified height logic
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
            topRight: Radius.circular(24),
          ),
        ),
        child: ListView(
          shrinkWrap: true,
          // physics:const NeverScrollableScrollPhysics(),
          children: children,
        ),
      ),
    );
  }
}
