import 'package:audio_diaries_flutter/core/usecases/font_scaler_detector_and_adjuster.dart';
import 'package:flutter/material.dart';

import '../../../../theme/components/cards.dart';
import '../../../../theme/custom_colors.dart';
import '../../../../theme/custom_typography.dart';

class SubmitLoadingPage extends StatefulWidget {
  const SubmitLoadingPage({super.key});

  @override
  State<SubmitLoadingPage> createState() => _SubmitLoadingPageState();
}

class _SubmitLoadingPageState extends State<SubmitLoadingPage> {
  String loadingText = "Submitting...";

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          loadingText = "Processing...";
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 5),
                 CircularProgressIndicator(
                  strokeWidth: getAdaptiveTextScaler(context).scale(6),
                  color: CustomColors.productNormalActive,
                ),
                const SizedBox(
                  height: 24,
                ),
                WordSafeText(
                  loadingText,
                  style: CustomTypography()
                      .headlineMedium(color: CustomColors.textSecondaryContent),
                ),
                const SizedBox(
                  height: 12,
                ),
                Text(
                  textScaler: getAdaptiveTextScaler(context),
                  "Hang tight while we process your responses - almost there!",
                  style: CustomTypography().bodyLarge(
                    color: CustomColors.textSecondaryContent,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                const WarningCard(
                  title: "Do Not Leave This Screen",
                  message: "Please stay on this screen until the upload is complete to ensure your diary is saved safely. Closing the app now may result in data loss."
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
