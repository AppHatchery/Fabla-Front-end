import 'package:flutter/material.dart';

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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: ShapeDecoration(
                color: CustomColors.fillVanilla,
                shape: RoundedRectangleBorder(
                  side: const BorderSide(
                      width: 2, color: CustomColors.pumpkinOrange),
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.warning_rounded,
                    color: CustomColors.pumpkinOrange,
                    size: 24,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 8,
                        children: [
                          Text(
                            "Do Not Leave This Screen",
                            style: CustomTypography().titleSmallCustom(
                              color: CustomColors.pumpkinOrange,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 0, vertical: 2),
                            decoration: ShapeDecoration(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4)),
                            ),
                            child: Text(
                              "Please stay on this screen until the upload is complete to ensure your diary is saved safely. Closing the app now may result in data loss.",
                              style: CustomTypography().bodyLarge(
                                color: CustomColors.pumpkinOrange,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
