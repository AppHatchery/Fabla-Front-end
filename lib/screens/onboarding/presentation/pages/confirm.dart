import 'dart:async';

import 'package:audio_diaries_flutter/core/usecases/font_scaler_detector.dart';
import 'package:audio_diaries_flutter/core/usecases/page_timer.dart';
import 'package:audio_diaries_flutter/screens/home/data/experiment.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/widgets/confirm_tile.dart';
import 'package:audio_diaries_flutter/services/pendo_service.dart';
import 'package:audio_diaries_flutter/services/preference_service.dart';
import 'package:audio_diaries_flutter/services/route_service.dart';
import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:io' show Platform;

import '../../../../theme/components/buttons.dart';
import '../../../../theme/custom_colors.dart';
// import '../../../../theme/dialogs/pop_ups.dart';

class ConfirmJoiningPage extends StatefulWidget {
  final ExperimentModel experiment;
  const ConfirmJoiningPage({super.key, required this.experiment});

  @override
  State<ConfirmJoiningPage> createState() => _ConfirmJoiningPageState();
}

class _ConfirmJoiningPageState extends State<ConfirmJoiningPage>
    with WidgetsBindingObserver {
  final PageTimer timer = PageTimer();
  TextScaler? scaler; // Get the size of the text scaler
  late bool isIos;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    timer.start();
    setState(() {
      isIos = Platform.isIOS;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      scaler = await fontScaler(context);
    });
    super.initState();
  }

  @override
  void dispose() {
    timer.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColors.backgroundSecondary,
      appBar: AppBar(
        backgroundColor: CustomColors.backgroundSecondary,
        scrolledUnderElevation: 0.0,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Study Information",
                  style: CustomTypography()
                      .headlineLarge(color: CustomColors.textWhite)),
              const SizedBox(
                height: 16,
              ),
              Text(
                  "Below is the study information associated with this study code.",
                  style: CustomTypography()
                      .bodyLarge(color: CustomColors.textWhite)),
              const SizedBox(
                height: 24,
              ),
              ConfrimTile(
                title: "Study Name",
                info: widget.experiment.name,
                icon: const Icon(
                  Icons.assured_workload_rounded,
                ),
              ),
              const SizedBox(
                height: 12,
              ),
              ConfrimTile(
                title: "Study Duration",
                info: widget.experiment.duration,
                icon: const Icon(
                  Icons.calendar_month_outlined,
                ),
              ),
              const SizedBox(
                height: 12,
              ),
              ConfrimTile(
                title: "Researcher Name",
                info: widget.experiment.researcher,
                icon: const Icon(
                  Icons.person_outline_rounded,
                ),
              ),
              const SizedBox(
                height: 12,
              ),
              TextButton(
                  onPressed: () => showResearchDetails(
                      context,
                      widget.experiment.name,
                      widget.experiment.duration,
                      widget.experiment.organization,
                      widget.experiment.researcher,
                      widget.experiment.description,
                      widget.experiment.login),
                  child: Text(
                    "View Study Details",
                    style: TextStyle(
                        color: CustomColors.textWhite,
                        fontFamily: CustomTypography.fontName,
                        fontSize: 18.sp,
                        decoration: TextDecoration.underline,
                        decorationColor: CustomColors.textWhite),
                  ))
            ],
          ),
        ),
      ),
      bottomNavigationBar: SizedBox(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            children: [
              CustomFlatButton(
                onClick: () => {
                  track(timer.stop(), "Finished"),
                  RouteService()
                      .navigate(null, context: context, current: 'confirm')
                },
                text: "Confirm Joining",
                color: CustomColors.fillWhite,
                textColor: CustomColors.productNormalActive,
              ),

              const SizedBox(
                height: 12,
              ),

              CustomFlatButton(
                onClick: () => {
                  track(timer.stop(), "Back"),
                  RouteService()
                      .navigateBack(context: context, current: 'confirm')
                },
                text: "This isn’t right - take me back",
                color: CustomColors.fillWhite,
                textColor: CustomColors.productNormalActive,
              ),

              isIos
                  ? const SizedBox(
                      height: 24,
                      width: double.infinity,
                    )
                  : const SizedBox.shrink()
              //CustomTextButton(onClick: ()=> null, text: "I HAVE A PROBLEM JOINING THE STUDY", textColor: CustomColors.textWhite,)
            ],
          ),
        ),
      ),
    );
  }

  void showResearchDetails(
      BuildContext context,
      String name,
      String duration,
      String organization,
      String researcher,
      String description,
      String login) async {
    // startTimer();
    // showModalBottomSheet(
    //     context: context,
    //     isScrollControlled: true,
    //     builder: (context) => Wrap(
    //           children: [
    //             BottomStudyInfoPopUp(
    //                 studyName: name,
    //                 description: description,
    //                 organisation: organization,
    //                 duration: duration,
    //                 researcher: researcher)
    //           ],
    //         )).then((value) async => {
    //       stopTimer(),
    await pendoTrack(login);
    // });
  }

  track(int spent, String status) async {
    await PendoService.track("Confirm Study", {
      "time_on_page": spent,
      "status": status,
      "Font Scaler": "$scaler"
    });
  }

  Future<void> pendoTrack(String login) async {
    final service = PreferenceService();
    final pendoID = await service.getStringPreference(key: 'pendo-ID');

    if (pendoID == null) {
      final anonymousID =
          "$login-anonymous-${DateTime.now().millisecondsSinceEpoch}";
      await service.setStringPreference(key: 'pendo-ID', value: anonymousID);
      await PendoService.start(anonymousID, login);
    } else {
      await PendoService.start(pendoID, login);
    }

    await PendoService.track("StudyDetails", null);
  }
}
