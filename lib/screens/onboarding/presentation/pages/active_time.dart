import 'package:audio_diaries_flutter/screens/onboarding/presentation/pages/notification_access.dart';
import 'package:flutter/material.dart';

import '../../../../theme/custom_colors.dart';
import '../../../../theme/custom_typography.dart';
import '../widgets/avatar_background.dart';

class ActiveTimePage extends StatefulWidget {
  const ActiveTimePage({super.key});

  @override
  State<ActiveTimePage> createState() => _ActiveTimePageState();
}

class _ActiveTimePageState extends State<ActiveTimePage> {
  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
        backgroundColor: CustomColors.backgroundSecondary,
        appBar: AppBar(
          backgroundColor: CustomColors.backgroundSecondary,
          leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: CustomColors.fillWhite,
                size: 32,
              )),
        ),
        body: SafeArea(
          bottom: false,
          child: LayoutBuilder(builder: (context, constraints) {
            final constraintHeight = constraints.maxHeight;
            return SingleChildScrollView(
              child: SizedBox(
                height: constraintHeight,
                width: width,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        "When would you like to take diaries?",
                        style: CustomTypography()
                            .headlineLarge(color: CustomColors.textWhite),
                      ),
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    Expanded(
                      child: SizedBox(
                        width: width,
                        child: AvatarBackground(
                            height: height,
                            width: width,
                            image:
                                "assets/images/avatar_ask_name.png", // Change Image
                            onContinue: () => Navigator.push(context, MaterialPageRoute(builder: (context)=> const NotificationAccessPage())),
                            children: const []),
                      ),
                    )
                  ],
                ),
              ),
            );
          }),
        ));
  }
}
