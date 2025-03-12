import 'package:audio_diaries_flutter/core/usecases/page_timer.dart';
import 'package:audio_diaries_flutter/main.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/widgets/camera_preview.dart';
import 'package:audio_diaries_flutter/services/pendo_service.dart';
import 'package:audio_diaries_flutter/services/preference_service.dart';
import 'package:audio_diaries_flutter/services/route_service.dart';
import 'package:audio_diaries_flutter/theme/components/buttons.dart';
import 'package:audio_diaries_flutter/theme/custom_colors.dart';
import 'package:audio_diaries_flutter/theme/custom_icons.dart';
import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:developer' as dev;

class CameraAccess extends StatefulWidget {
  const CameraAccess({super.key});

  @override
  State<CameraAccess> createState() => _CameraAccessState();
}

class _CameraAccessState extends State<CameraAccess>
    with WidgetsBindingObserver {
  bool permission = false;
  bool requested = false;
  bool canGoBack = false;

  late CameraController controller;

  final PageTimer timer = PageTimer();

  @override
  initState() {
    WidgetsBinding.instance.addObserver(this);
    timer.start();
    if (Navigator.of(context).canPop()) {
      canGoBack = true;
    }
    controller = CameraController(
      cameras[0],
      ResolutionPreset.max,
    );
    super.initState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      timer.start();
    } else if (state == AppLifecycleState.paused) {
      int spent = timer.stop();
      track(spent, "Paused");
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  dispose() {
    controller.dispose();
    timer.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
        backgroundColor: CustomColors.backgroundSecondary,
        appBar: AppBar(
          backgroundColor: CustomColors.backgroundSecondary,
          scrolledUnderElevation: 0.0,
          leading: canGoBack
              ? IconButton(
                  onPressed: () =>
                      {track(timer.stop(), "Back"), Navigator.pop(context)},
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: CustomColors.fillWhite,
                    size: 32,
                  ))
              : null,
          automaticallyImplyLeading: false,
        ),
        body: LayoutBuilder(builder: (context, constraints) {
          return Padding(
            padding:
                const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 34.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraint) => SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(minHeight: constraint.maxHeight),
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                children: [
                                  Text(
                                    permission
                                        ? "Let's test the camera feed."
                                        : "Let's enable access to your camera.",
                                    style: CustomTypography().headlineLarge(
                                        color: CustomColors.textWhite),
                                  ),
                                  const SizedBox(height: 24),
                                  requested == true && permission == false
                                      ? Container(
                                          width: width,
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: CustomColors.warningFill,
                                            border: Border.all(
                                              color: CustomColors.warningActive,
                                              width: 2,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(11),
                                          ),
                                          child: Column(
                                            children: [
                                              Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Icon(CustomIcons.cancel,
                                                      size: 20,
                                                      color: CustomColors
                                                          .warningActive),
                                                  const SizedBox(
                                                    width: 10,
                                                  ),
                                                  Flexible(
                                                    child: Text(
                                                      "Oops! You need to enable camera access to participate in the study.",
                                                      style: CustomTypography()
                                                          .bodyLarge(
                                                              color: CustomColors
                                                                  .warningActive),
                                                    ),
                                                  )
                                                ],
                                              ),
                                              const SizedBox(height: 12),
                                              Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const SizedBox(
                                                      height: 20, width: 20),
                                                  const SizedBox(
                                                    width: 10,
                                                  ),
                                                  TextButton(
                                                      style:
                                                          TextButton.styleFrom(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 8,
                                                                vertical: 4),
                                                        alignment:
                                                            Alignment.center,
                                                        backgroundColor:
                                                            CustomColors
                                                                .warningActive,
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(11),
                                                        ),
                                                      ),
                                                      onPressed:
                                                          openPermissionSettings,
                                                      child: Text(
                                                          "Open Settings",
                                                          style: CustomTypography()
                                                              .bodyLarge(
                                                                  color: CustomColors
                                                                      .textWhite)))
                                                ],
                                              ),
                                            ],
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                                ],
                              ),
                              Visibility(
                                visible: permission,
                                replacement: SizedBox(
                                  width: width,
                                  child: Image.asset(
                                      'assets/images/phone_camera.png'),
                                ),
                                child: SizedBox(
                                    height: 378,
                                    width: width,
                                    child: controller.value.isInitialized
                                        ? CustomCameraPreview(
                                            controller: controller)
                                        : SizedBox.shrink()),
                              ),
                            ]),
                      ),
                    ),
                  ),
                ),
                CustomFlatButton(
                  onClick: () => navigateToNextPage(context),
                  text: "Continue",
                  color: CustomColors.fillWhite,
                  isDisabled: requested == true && permission == false,
                  textColor: CustomColors.productNormalActive,
                )
              ],
            ),
          );
        }));
  }

  navigateToNextPage(BuildContext context) async {
    if (permission) {
      if (requested) {
        await PreferenceService()
            .setBoolPreference(key: 'camera', value: requested);
        if (context.mounted) {
          track(timer.stop(), "Finished");
          RouteService().navigate(null, context: context, current: 'camera');
        }
      }
    } else {
      cameraInit();
    }
  }

  track(int spent, String status) async {
    await PendoService.track(
        "Camera Access", {"time_on_page": spent, "status": status});
  }

  cameraInit() async {
    controller.initialize().then((_) {
      if (mounted) {
        setState(() {
          permission = true;
          requested = true;
        });
      }
    }).catchError((Object e) {
      if (e is CameraException) {
        dev.log('Error: ${e.code}\nError Message: ${e.description}',
            name: 'Camera Access - Camera Init');
        switch (e.code) {
          case 'CameraAccessDenied':
            setState(() {
              permission = false;
              requested = true;
            });
            break;
          case 'CameraAccessDeniedWithoutPrompt':
            setState(() {
              permission = false;
              requested = true;
            });
            break;
          default:
            // Handle other errors here.
            break;
        }
      }
    });
  }

  void openPermissionSettings() async {
    bool opened = await openAppSettings();

    if (opened) {
      final results = await Permission.camera.request();
      setState(() {
        permission = results.isGranted;
      });

      if (permission) cameraInit();
    }
  }
}
