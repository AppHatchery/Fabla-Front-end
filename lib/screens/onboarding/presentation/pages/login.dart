import 'package:audio_diaries_flutter/screens/onboarding/presentation/cubit/login/login_cubit.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/pages/confirm.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/widgets/verification_code.dart';
import 'package:audio_diaries_flutter/theme/components/buttons.dart';
import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../theme/custom_colors.dart';
import '../../../../theme/resources/strings.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late LoginCubit loginCubit;
  final TextEditingController controller = TextEditingController();
  bool error = false;

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
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            child: SizedBox(
              height: height - 40,
              width: width,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 70, 16, 60),
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
                              style: CustomTypography().headlineLarge(
                                  color: CustomColors.textWhite)),
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
                          BlocConsumer<LoginCubit, LoginState>(
                              builder: (context, state) {
                            if (state is LoginInitial) {
                              return initialLogin();
                            } else if (state is LoginLoading) {
                              return loading();
                            }
                            return initialLogin();
                          }, listener: (context, state) {
                            if (state is LoginSuccess) {
                              error = false;
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const ConfrimJoiningPage()));
                            } else if (state is LoginError) {
                              setState(() {
                                error = true;
                              });
                            }
                          })
                        ],
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Need help with the verification code? ",
                          style: CustomTypography()
                              .bodyMedium(color: CustomColors.textWhite),
                        ),
                        GestureDetector(
                            onTap: () => launchEmail(),
                            child: Text(
                              "Contact us",
                              style: TextStyle(
                                  fontSize:
                                      CustomTypography().bodyMedium().fontSize,
                                  fontWeight: CustomTypography()
                                      .bodyMedium()
                                      .fontWeight,
                                  decoration: TextDecoration.underline,
                                  decorationColor: CustomColors.textWhite,
                                  color: CustomColors.textWhite),
                            )),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget initialLogin() {
    return Column(
      children: [
        VerificationCodeTextField(
          controller: controller,
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
    );
  }

//  Add Loading State
  Widget loading() {
    return Column(
      children: [
        VerificationCodeTextField(
          controller: controller,
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
    );
  }

  void login() {
    if (controller.text.isNotEmpty) {
      final lastNonSpaceIndex = controller.text.lastIndexOf(RegExp(r'[^ ]'));
      final text = controller.text.substring(0, lastNonSpaceIndex + 1);
      final code = int.tryParse(text);
      ;
      if (code != null) {
        loginCubit.login(code);
      } else {}
    }
  }

  Future<void> launchEmail() async {
    final uri = Uri(
        scheme: "mailto",
        path: "support@apphatchery.org",
        query: encodeQueryParameters(<String, String>{
          'subject': 'Need help with the verification code',
          'body': 'I have a problem with my study code:'
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
