import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import '../../../../theme/custom_colors.dart';

class AvatarBackground extends StatefulWidget {
  final List<Widget> children;
  final double height;
  final double width;
  final double foregroundHeight;
  final String image;
  final String avatarType;
  final String? animation;
  final double? keyboardSpace;
  final bool scrollable;
  final VoidCallback onContinue;
  final String? stateMachineName;
  final void Function(RiveWidgetController)? onControllerReady;

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
    this.scrollable = true,
    required this.onContinue,
    this.stateMachineName,
    this.onControllerReady,
  });

  @override
  State<AvatarBackground> createState() => _AvatarBackgroundState();
}

class _AvatarBackgroundState extends State<AvatarBackground> {
  RiveWidgetController? _riveController;
  double _animationHeight = 0;

  @override
  void initState() {
    super.initState();
    if (widget.avatarType == "animation" && widget.animation != null) {
      _loadRive(widget.animation!);
    }
  }

  @override
  void didUpdateWidget(AvatarBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animation != oldWidget.animation ||
        widget.stateMachineName != oldWidget.stateMachineName) {
      _riveController?.dispose();
      _riveController = null;
      _animationHeight = 0;
      if (widget.avatarType == "animation" && widget.animation != null) {
        _loadRive(widget.animation!);
      }
    }
  }

  Future<void> _loadRive(String assetPath) async {
    final file = await File.asset(
      assetPath,
      riveFactory: Factory.rive,
    );
    if (!mounted || file == null) return;
    final controller = widget.stateMachineName != null
        ? RiveWidgetController(
            file,
            stateMachineSelector:
                StateMachineSelector.byName(widget.stateMachineName!),
          )
        : RiveWidgetController(file);

    final artboard = controller.artboard;
    final computedHeight = artboard.width > 0
        ? widget.width * (artboard.height / artboard.width)
        : widget.width;

    setState(() {
      _riveController = controller;
      _animationHeight = computedHeight;
    });
    widget.onControllerReady?.call(controller);
  }

  @override
  void dispose() {
    _riveController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildAvatarLayer(),
        _buildForegroundLayer(),
      ],
    );
  }

  Widget _buildAvatarLayer() {
    return Positioned(
      top: 10,
      left: 0,
      right: 0,
      child: widget.avatarType == "image"
          ? Image.asset(widget.image, width: widget.width)
          : SizedBox(
              height: _animationHeight,
              width: widget.width,
              child: _riveController != null
                  ? RiveWidget(
                      controller: _riveController!,
                      fit: Fit.fitWidth,
                    )
                  : const SizedBox.shrink(),
            ),
    );
  }

  Widget _buildForegroundLayer() {
    return Positioned(
      top: _animationHeight * widget.foregroundHeight,
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        width: widget.width,
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
          children: widget.children,
        ),
      ),
    );
  }
}
