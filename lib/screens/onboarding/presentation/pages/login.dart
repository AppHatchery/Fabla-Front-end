import 'package:audio_diaries_flutter/screens/onboarding/presentation/cubit/login/login_cubit.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/pages/confirm.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/widgets/verification_code.dart';
import 'package:audio_diaries_flutter/theme/components/buttons.dart';
import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
    return Scaffold(
      backgroundColor: CustomColors.backgroundSecondary,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 70, 16, 60),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset(
                    "assets/images/avatar_diary.png",
                    height: 52,
                    width: 52,
                  ),
                  const SizedBox(
                    height: 24,
                  ),
                  Text("Welcome to Dayrio! ${Strings.wavingEmoji}",
                      style: CustomTypography()
                          .headlineLarge(color: CustomColors.textWhite)),
                  const SizedBox(
                    height: 24,
                  ),
                  Text(
                      "Dayrio is a tool for EMA, audio diary research and more ${Strings.telescope}",
                      style: CustomTypography()
                          .titleSmall(color: CustomColors.textWhite)),
                  const SizedBox(
                    height: 24,
                  ),
                  // ADD HERE
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
                              builder: (context) => const ConfrimJoiningPage()));
                    } else if (state is LoginError) {
                      setState(() {
                        error = true;
                      });
                    }
                  })
                ],
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
        CustomElevatedButton(
          onClick: () => login(),
          text: "LOGIN",
          color: CustomColors.fillWhite,
          shadowColor: CustomColors.fillNormal,
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
        CustomElevatedButton(
          onClick: () => login(),
          text: "LOGIN",
          color: CustomColors.fillWhite,
          shadowColor: CustomColors.productBorderNormal,
          textColor: CustomColors.productNormalActive,
        )
      ],
    );
  }

  void login() {
    if (controller.text.isNotEmpty) {
      loginCubit.login(controller.text);
    }
  }
}
