import 'package:audio_diaries_flutter/main.dart';
import 'package:audio_diaries_flutter/theme/custom_colors.dart';
import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gradient_borders/box_borders/gradient_box_border.dart';

class CustomCameraPreview extends StatefulWidget {
  final CameraController? controller;
  const CustomCameraPreview({super.key, this.controller});

  @override
  State<CustomCameraPreview> createState() => _CustomCameraPreviewState();
}

class _CustomCameraPreviewState extends State<CustomCameraPreview> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          child: Image.asset('assets/images/sparkles.png'),
        ),
        Center(
          child: Container(
            height: 268,
            width: 323,
            decoration: BoxDecoration(
                border: const GradientBoxBorder(
                  gradient: LinearGradient(
                      colors: [Color(0xFFABD0FE), Color(0xFF595EF2)]),
                  width: 4,
                ),
                borderRadius: BorderRadius.circular(4)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: ClipRect(
                        child: FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width:
                                widget.controller?.value.previewSize?.height ?? 0,
                            height:
                                widget.controller?.value.previewSize?.width ?? 0,
                            child: CameraPreview(widget.controller!),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      icon: Icon(CupertinoIcons.switch_camera),
                      onPressed: changeCameraLens,
                      color: CustomColors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  changeCameraLens() {
    final currentLensDirection = widget.controller!.description.lensDirection;
    CameraDescription lens = cameras[0];

    for (final camera in cameras) {
      if (camera.lensDirection != currentLensDirection) {
        lens = camera;
        break;
      }
    }

    if (widget.controller != null) widget.controller!.setDescription(lens);
  }
}
