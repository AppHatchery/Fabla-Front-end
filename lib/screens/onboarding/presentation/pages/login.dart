import 'package:audio_diaries_flutter/screens/onboarding/presentation/cubit/login/login_cubit.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/pages/welcome.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/widgets/verification_code.dart';
import 'package:audio_diaries_flutter/theme/components/buttons.dart';
import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../theme/custom_colors.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late LoginCubit loginCubit;
  final TextEditingController controller = TextEditingController();
  bool error = false;
  String message = '';

  @override
  void initState() {
    loginCubit = BlocProvider.of<LoginCubit>(context);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: CustomColors.backgroundSecondary,
      appBar: AppBar(
          backgroundColor: CustomColors.backgroundSecondary,
          scrolledUnderElevation: 0.0,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded),
            color: CustomColors.textWhite,
          )),
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
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 34),
              child: BlocConsumer<LoginCubit, LoginState>(
                  builder: (context, state) {
                if (state is LoginInitial) {
                  return initialLogin();
                } else if (state is LoginLoading) {
                  return loading(height - 200);
                }
                return initialLogin();
              }, listener: (context, state) {
                if (state is LoginSuccess) {
                  error = false;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const WelcomePage()),
                  );
                } else if (state is LoginError) {
                  setState(() {
                    error = true;
                    message = state.message;
                  });
                }
              }),
            ),
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
    if (controller.text.isNotEmpty) {
      final lastNonSpaceIndex = controller.text.lastIndexOf(RegExp(r'[^ ]'));
      final text = controller.text.substring(0, lastNonSpaceIndex + 1);
      final code = text;

      if (code.isNotEmpty) {
        loginCubit.login(code);
      } else {}
    }
  }

  Future<void> launchEmail() async {
    final uri = Uri(
        scheme: "mailto",
        path: "support@apphatchery.org",
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
