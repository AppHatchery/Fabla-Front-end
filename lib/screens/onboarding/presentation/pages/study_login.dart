import 'package:audio_diaries_flutter/screens/onboarding/presentation/cubit/login/study_login_cubit.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/pages/confirm.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/widgets/verification_code.dart';
import 'package:audio_diaries_flutter/theme/components/buttons.dart';
import 'package:audio_diaries_flutter/theme/custom_colors.dart';
import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:audio_diaries_flutter/theme/resources/strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

class StudyLogin extends StatefulWidget {
  const StudyLogin({super.key});

  @override
  State<StudyLogin> createState() => _StudyLoginState();
}

class _StudyLoginState extends State<StudyLogin> {
  final TextEditingController controller = TextEditingController();
  bool error = false;
  String message = '';

  late StudyLoginCubit cubit;

  @override
  void initState() {
    cubit = BlocProvider.of<StudyLoginCubit>(context);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: CustomColors.backgroundSecondary,
      body: SafeArea(
          top: true,
          left: false,
          right: false,
          bottom: false,
          child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: SizedBox(
                height: height,
                width: width,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 70, 16, 34),
                  child: BlocConsumer<StudyLoginCubit, StudyLoginState>(
                      builder: (context, state) {
                    if (state is StudyLoginInitial) {
                      return initialLogin();
                    } else if (state is StudyLoginLoading) {
                      return loading(height - 100);
                    }

                    return initialLogin();
                  }, listener: (context, state) {
                    if (state is StudyLoginError) {
                      setState(() {
                        error = true;
                        message = state.message;
                      });
                    } else if (state is StudyLoginSuccess) {
                      error = false;
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ConfrimJoiningPage(
                                    experiment: state.experiment,
                                  )));
                    }
                  }),
                ),
              ))),
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
                        "Fabla is a tool for EMA, audio diary research and more ${Strings.telescope}",
                        style: CustomTypography()
                            .titleSmall(color: CustomColors.textWhite)),
                    const SizedBox(
                      height: 24,
                    ),
                    VerificationCodeTextField(
                      title: "Study Code",
                      errorMessage: message,
                      hint: 'Enter the study code...',
                      controller: controller,
                      fieldType: TextInputType.text,
                      error: error,
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
                      "Need help with the study code? ",
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
            "Hang tight while we verify the study code - \nalmost there!",
            textAlign: TextAlign.center,
            style: CustomTypography().bodyLarge(color: CustomColors.textWhite),
          ),
        ],
      ),
    );
  }

  void verify() {
    if (controller.text.isNotEmpty) {
      final lastNonSpaceIndex = controller.text.lastIndexOf(RegExp(r'[^ ]'));
      final code = controller.text.substring(0, lastNonSpaceIndex + 1);

      if (code.isNotEmpty) {
        cubit.login(code);
      } else {}
    }
  }

  Future<void> launchEmail() async {
    final uri = Uri(
        scheme: "mailto",
        path: "support@apphatchery.org",
        query: encodeQueryParameters(<String, String>{
          'subject': 'Need help with the study code',
          'body': 'I have a problem with accessing the study: '
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
