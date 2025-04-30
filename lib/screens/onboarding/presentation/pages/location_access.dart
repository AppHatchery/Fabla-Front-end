import 'package:app_settings/app_settings.dart';
import 'package:audio_diaries_flutter/core/usecases/page_timer.dart';
import 'package:audio_diaries_flutter/services/pendo_service.dart';
import 'package:audio_diaries_flutter/services/preference_service.dart';
import 'package:audio_diaries_flutter/services/route_service.dart';
import 'package:audio_diaries_flutter/theme/components/buttons.dart';
import 'package:audio_diaries_flutter/theme/custom_colors.dart';
import 'package:audio_diaries_flutter/theme/custom_icons.dart';
import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart' as l;
import 'package:permission_handler/permission_handler.dart';
import 'package:rive/rive.dart' as rive;

class LocationAccess extends StatefulWidget {
  const LocationAccess({super.key});

  @override
  State<LocationAccess> createState() => _LocationAccessState();
}

class _LocationAccessState extends State<LocationAccess>
    with WidgetsBindingObserver {
  bool permission = false;
  bool requested = false;
  bool canGoBack = false;

  //Animations
  late rive.StateMachineController _controller;

  final PageTimer timer = PageTimer();

  late l.Location location;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    timer.start();
    if (Navigator.of(context).canPop()) {
      canGoBack = true;
    }

    location = l.Location();
    super.initState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      checkForPermission();
      timer.start();
    } else if (state == AppLifecycleState.paused) {
      int spent = timer.stop();
      track(spent, "Paused");
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  void dispose() {
    _controller.dispose();
    timer.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return Scaffold(
        backgroundColor: CustomColors.backgroundSecondary,
        appBar: AppBar(
          backgroundColor: CustomColors.backgroundSecondary,
          scrolledUnderElevation: 0.0,
          leading: IconButton(
              onPressed: () => {
                    track(timer.stop(), "Back"),
                    RouteService()
                        .navigateBack(context: context, current: 'location')
                  },
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: CustomColors.fillWhite,
                size: 32,
              )),
          automaticallyImplyLeading: false,
        ),
        body: LayoutBuilder(builder: (context, constraints) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraint) => SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraint.maxHeight),
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Column(
                                children: [
                                  Text(
                                    "Let's enable access to your location.",
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
                                                      "Oops! You need to enable location access to participate in the study.",
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
                            ),
                            SizedBox(
                              height: height * 0.25,
                              width: width,
                              child: rive.RiveAnimation.asset(
                                'assets/animations/onboarding/location.riv',
                                fit: BoxFit.fitWidth,
                                onInit: onInit,
                              ),
                            ),
                            SizedBox(
                              width: width,
                              child: Image.asset(
                                  'assets/images/phone_location.png'),
                            )
                          ]),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 34),
                child: CustomFlatButton(
                  onClick: () => navigateToNextPage(context),
                  text: "Continue",
                  color: CustomColors.fillWhite,
                  isDisabled: requested == true && permission == false,
                  textColor: CustomColors.productNormalActive,
                ),
              )
            ],
          );
        }));
  }

  navigateToNextPage(BuildContext context) async {
    final results = await location.requestPermission();
    setState(() {
      permission = results == l.PermissionStatus.granted;
      requested = true;
    });
    await PendoService.track("Location Access", {"state": results.name});
    if (permission) {
      if (requested) {
        await PreferenceService()
            .setBoolPreference(key: 'location', value: requested);
        if (context.mounted) {
          track(timer.stop(), "Finished");
          RouteService().navigate(null, context: context, current: 'location');
        }
      }
    }
  }

  onInit(rive.Artboard art) async {
    var ctrl = rive.StateMachineController.fromArtboard(art, "Animation_3");
    ctrl?.isActive = false;

    if (ctrl != null) {
      art.addController(ctrl);
      setState(() {
        _controller = ctrl;
        art.addController(_controller);
        ctrl.isActive = true;
      });
    }
  }

  void openPermissionSettings() async =>
      await AppSettings.openAppSettings(type: AppSettingsType.settings);

  checkForPermission() async {
    final result = await Permission.location.isGranted;
    if (mounted) setState(() => permission = result);
  }

  track(int spent, String status) async {
    await PendoService.track(
        "Location Access", {"time_on_page": spent, "status": status});
  }
}
