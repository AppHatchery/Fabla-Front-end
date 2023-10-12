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
      setState(() {
        loadingText = "Processing...";
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: CustomColors.productNormalActive,
          ),
          Text(
            loadingText,
            style: CustomTypography()
                .headlineMedium(color: CustomColors.textSecondaryContent),
          ),
          Text(
            "Hang tight while we process your responses - almost there!",
            style: CustomTypography().bodyLarge(
              color: CustomColors.textSecondaryContent,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
