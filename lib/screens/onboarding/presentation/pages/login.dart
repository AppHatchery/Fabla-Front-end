import 'dart:math';

import 'package:audio_diaries_flutter/core/usecases/font_scaler_detector.dart';
import 'package:audio_diaries_flutter/core/usecases/page_timer.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/cubit/login/login_cubit.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/widgets/verification_code.dart';
import 'package:audio_diaries_flutter/services/route_service.dart';
import 'package:audio_diaries_flutter/services/pendo_service.dart';
import 'package:audio_diaries_flutter/theme/components/buttons.dart';
import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rive/rive.dart' hide Image;
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;

import '../../../../theme/custom_colors.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with WidgetsBindingObserver {
  final PageTimer timer = PageTimer();
  TextScaler? scaler; // Get the size of the text scaler
  late LoginCubit loginCubit;
  final TextEditingController controller = TextEditingController();
  bool error = false;
  bool warning = false;
  String message = '';
  String warnMessage = '';

  late StateMachineController _controller;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    timer.start();
    loginCubit = BlocProvider.of<LoginCubit>(context);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      scaler = await fontScaler(context);
    });
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    timer.dispose();
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
    final width = MediaQuery.of(context).size.width;
    final isIos = Platform.isIOS;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: CustomColors.backgroundSecondary,
      appBar: AppBar(
          backgroundColor: CustomColors.backgroundSecondary,
          scrolledUnderElevation: 0.0,
          leading: IconButton(
            onPressed: () => {
              track(timer.stop(), "Back"),
              RouteService()
                  .navigateBack(context: context, current: 'participant_login')
            },
            icon: const Icon(Icons.arrow_back_rounded),
            color: CustomColors.textWhite,
          )),
      body: SafeArea(
        bottom: false,
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Stack(
            children: [
              Positioned(
                top: -223,
                left: 0,
                child: Transform.flip(
                  flipX: true,
                  flipY: true,
                  child: SizedBox(
                    height: 380,
                    width: 380,
                    child: RiveAnimation.asset(
                      'assets/animations/onboarding/hide_peek.riv',
                      fit: BoxFit.fitWidth,
                      onInit: onInit,
                    ),
                  ),
                ),
              ),

              Padding(
                padding: EdgeInsets.fromLTRB(
                    16,
                    70,
                    16,
                    bottomPadding > 0
                        ? bottomPadding + 34
                        : (isIos ? 34 + 34 : 34)),
                child: BlocConsumer<LoginCubit, LoginState>(
                    builder: (context, state) {
                  if (state is LoginInitial) {
                    return initialLogin();
                  } else if (state is LoginLoading) {
                    return Center(child: loading(height - 200));
                  }
                  return initialLogin();
                }, listener: (context, state) {
                  if (state is LoginSuccess) {
                    error = false;
                    warning = false;
                    RouteService().navigate(null,
                        context: context, current: 'participant_login');
                  } else if (state is LoginWarning) {
                    setState(() {
                      error = false;
                      warning = true;
                      warnMessage = state.message;
                    });
                  } else if (state is LoginError) {
                    setState(() {
                      error = true;
                      warning = false;
                      message = state.message;
                    });
                  }
                }),
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
                    Text("Participant Login",
                        style: CustomTypography()
                            .headlineLarge(color: CustomColors.textWhite)),
                    const SizedBox(
                      height: 24,
                    ),
                    Text(
                        "Please enter the participant ID you were given by the researchers here.",
                        style: CustomTypography()
                            .titleSmall(color: CustomColors.textWhite)),
                    const SizedBox(
                      height: 24,
                    ),
                    VerificationCodeTextField(
                      title: "Participant ID",
                      errorMessage: message,
                      hint: "Enter your participant ID...",
                      controller: controller,
                      fieldType: TextInputType.text,
                      error: error,
                      warning: warning,
                      warningMessage: warnMessage,
                    ),
                    const SizedBox(
                      height: 24,
                    ),
                    CustomFlatButton(
                      onClick: () => login(),
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
                      "Need help with the participant ID? ",
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
            "Signing in...",
            style: CustomTypography()
                .headlineMedium(color: CustomColors.textWhite),
          ),
          const SizedBox(
            height: 12,
          ),
          Text(
            "Hang tight while we sign you up - \nalmost there!",
            textAlign: TextAlign.center,
            style: CustomTypography().bodyLarge(color: CustomColors.textWhite),
          ),
        ],
      ),
    );
  }

  void login() {
    final code = controller.text.trim();

      if (code.isNotEmpty) {
        loginCubit.login(code);
      } else {
        setState(() {
          error = true;
          message = 'Oops! We cannot access your study without a valid Participant ID.';
        });
        return;
      }
  }

  onInit(Artboard art) async {
    var ctrl = StateMachineController.fromArtboard(art, "Animation_8");
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

  track(int spent, String status) async {
    await PendoService.track("Participant Login",
        {"time_on_page": spent, "status": status, "Font Scaler": "$scaler"});
  }

  Future<void> launchEmail() async {
    final uri = Uri(
        scheme: "mailto",
        path: "fabla@emory.edu",
        query: encodeQueryParameters(<String, String>{
          'subject': 'Need help with the participant ID',
          'body': 'I have a problem with my participant ID:'
        }));

    await launchUrl(uri);
  }

  String? encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((MapEntry<String, String> e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }
}
