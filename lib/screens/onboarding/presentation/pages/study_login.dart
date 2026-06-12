import 'package:audio_diaries_flutter/core/usecases/font_scaler_detector.dart';
import 'package:audio_diaries_flutter/core/usecases/page_timer.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/cubit/login/study_login_cubit.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/widgets/verification_code.dart';
import 'package:audio_diaries_flutter/services/route_service.dart';
import 'package:audio_diaries_flutter/theme/components/buttons.dart';
import 'package:audio_diaries_flutter/theme/custom_colors.dart';
import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:audio_diaries_flutter/theme/resources/strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:math' show pi;
import 'package:rive/rive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;
import '../../../../core/utils/participant_experiment_details.dart';
import '../../../../services/pendo_service.dart';

class StudyLogin extends StatefulWidget {
  const StudyLogin({super.key});

  @override
  State<StudyLogin> createState() => _StudyLoginState();
}

class _StudyLoginState extends State<StudyLogin> with WidgetsBindingObserver {
  final PageTimer timer = PageTimer();
  TextScaler? scaler; // Get the size of the text scaler

  final TextEditingController controller = TextEditingController();
  bool error = false;
  String message = '';

  File? _riveFile;
  RiveWidgetController? _riveController;

  late StudyLoginCubit cubit;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    cubit = BlocProvider.of<StudyLoginCubit>(context);
    timer.start();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      scaler = await fontScaler(context);
    });
    _loadRive();
    super.initState();
  }

  Future<void> _loadRive() async {
    final file = await File.asset(
      'assets/animations/onboarding/hide_peek.riv',
      riveFactory: Factory.rive,
    );
    if (file != null && mounted) {
      setState(() {
        _riveFile = file;
        _riveController = RiveWidgetController(
          file,
          stateMachineSelector: StateMachineSelector.byName('Animation_8'),
        );
      });
    }
  }

  @override
  void dispose() {
    _riveController?.dispose();
    _riveFile?.dispose();
    controller.dispose();
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
    final height = MediaQuery.of(context).size.height;
    final isIos = Platform.isIOS;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: CustomColors.backgroundSecondary,
      body: SafeArea(
        bottom: false,
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Stack(
            children: [
              Positioned(
                bottom: 20,
                left: -182.5,
                child: Transform.rotate(
                  angle: pi * 5.4 / 4,
                  child: Transform.flip(
                    flipX: true,
                    flipY: true,
                    child: SizedBox(
                      height: 340,
                      width: 340,
                      child: _riveController != null
                          ? RiveWidget(
                              controller: _riveController!,
                              fit: Fit.fitWidth,
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),

              Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  70,
                  16,
                  MediaQuery.of(context).viewInsets.bottom > 0
                      ? MediaQuery.of(context).viewInsets.bottom + 16
                      : (bottomPadding > 0
                      ? bottomPadding + 34
                      : (isIos ? 68 : 34)),
                ),
              child: BlocConsumer<StudyLoginCubit, StudyLoginState>(
                  builder: (context, state) {
                    if (state is StudyLoginInitial) {
                      return initialLogin();
                    } else if (state is StudyLoginLoading) {
                      return Center(child: loading(height - 100));
                    }

                    return initialLogin();
                  },
                  listener: (context, state) {
                    if (state is StudyLoginError) {
                      setState(() {
                        error = true;
                        message = state.message;
                      });
                    } else if (state is StudyLoginSuccess) {
                      error = false;
                      int spent = timer.stop();
                      track(spent, "Finished");
                      RouteService().navigate(
                        state.experiment,
                        context: context,
                        current: 'login',
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget initialLogin() {
    return LayoutBuilder(builder: (context, constraints) {
      return SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: constraints.maxHeight,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.asset(
                      "assets/images/logo_white.png",
                      height: 52,
                      width: 52,
                    ),
                    const SizedBox(
                      height: 24,
                    ),
                    Text("Welcome to Fabla! ${Strings.wavingEmoji}",
                        style: CustomTypography()
                            .headlineLarge(color: CustomColors.textWhite)),
                    const SizedBox(
                      height: 24,
                    ),
                    Text(
                        "Fabla is a tool for daily experience research, audio diaries and more ${Strings.telescope}",
                        style: CustomTypography()
                            .titleSmall(color: CustomColors.textWhite)),
                    const SizedBox(
                      height: 24,
                    ),
                    VerificationCodeTextField(
                      title: "Study String",
                      errorMessage: message,
                      hint: 'Enter the study string...',
                      controller: controller,
                      fieldType: TextInputType.text,
                      error: error,
                      warningMessage: '',
                    ),
                    const SizedBox(
                      height: 24,
                    ),
                    CustomFlatButton(
                      onClick: () => verify(),
                      text: "Login",
                      color: CustomColors.fillWhite,
                      textColor: CustomColors.productNormalActive,
                    )
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      "Need help with the study string? ",
                      style: CustomTypography()
                          .bodyMedium(color: CustomColors.textWhite),
                    ),
                  ),
                  GestureDetector(
                      onTap: () => launchEmail(),
                      child: Text(
                        "Contact us",
                        style: TextStyle(
                            fontSize: CustomTypography().bodyMedium().fontSize,
                            fontWeight:
                                CustomTypography().bodyMedium().fontWeight,
                            decoration: TextDecoration.underline,
                            decorationColor: CustomColors.textWhite,
                            color: CustomColors.textWhite),
                      )),
                ],
              )
            ],
          ),
        ),
      );
    });
  }

  //  Add Loading State
  Widget loading(double height) {
    return SizedBox(
      height: height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
              strokeCap: StrokeCap.round,
              strokeWidth: 8,
              backgroundColor: CustomColors.fillWhite,
              color: CustomColors.productBorderActive),
          const SizedBox(
            height: 24,
          ),
          Text(
            "Verifying...",
            style: CustomTypography()
                .headlineMedium(color: CustomColors.textWhite),
          ),
          const SizedBox(
            height: 12,
          ),
          Text(
            "Hang tight while we verify the study string - \nalmost there!",
            textAlign: TextAlign.center,
            style: CustomTypography().bodyLarge(color: CustomColors.textWhite),
          ),
        ],
      ),
    );
  }

  void verify() {
    final code = controller.text.trim();

      if (code.isNotEmpty) {
        cubit.login(code);
      } else {
        setState(() {
          error = true;
          message = 'Oops! We cannot access your study without a valid Study ID.';
        });
        return;
      }
  }

Future<void> launchEmail() async {
    await ParticipantAndExperimentDetails().loginSupportEmail(
        subject: 'Fabla Participant Login Issue',
        body: 'Describe the issue you are facing:',
        example: 'My study string is not working'
    );
  }

  Future<void> track(int spent, String status) async {
    await PendoService.track("Study Login",
        {"time_on_page": spent, "status": status, "Font Scaler": "$scaler"});
  }
}
