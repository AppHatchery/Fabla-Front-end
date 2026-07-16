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
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              strokeWidth: 6,
              color: CustomColors.productNormalActive,
            ),
            const SizedBox(
              height: 24,
            ),
            Text(
              loadingText,
              style: CustomTypography()
                  .headlineMedium(color: CustomColors.textSecondaryContent),
            ),
            const SizedBox(
              height: 12,
            ),
            Text(
              "Hang tight while we process your responses - almost there!",
              style: CustomTypography().bodyLarge(
                color: CustomColors.textSecondaryContent,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            const WarningCard(
              title: "Do Not Leave This Screen",
              message: "Please stay on this screen until the upload is complete to ensure your diary is saved safely. Closing the app now may result in data loss.",
              icon: Icons.warning_rounded,
            ),
          ],
        ),
      ),
    );
  }
}
