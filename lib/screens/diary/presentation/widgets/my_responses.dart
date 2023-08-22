import 'package:flutter/material.dart';

import '../../../../theme/components/buttons.dart';
import '../../../../theme/components/cards.dart';
import '../../../../theme/custom_colors.dart';
import '../../../../theme/custom_typography.dart';

/// This class is the UI element that is displayed when the user selects the option "RECORD RESPONSE"
/// and has recorded an audio
/// it displays the Audio that the user has recorded
/// and a button for them to add a new response(no functionality yet)
/// the My response section, to be changed into a  list in case of multiple responses
class MyResponse extends StatelessWidget {
  const MyResponse({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "My Response",
          style: CustomTypography()
              .titleLarge(color: CustomColors.textNormalContent),
        ),
        const SizedBox(height: 12),
        const AudioDiaryCard(
          path:"",
        ),
        const SizedBox(height: 12),
        CustomElevatedButton(
          onClick: () {},
          text: "ADD A NEW RESPONSE",
          color: CustomColors.productLightPrimaryNormalWhite,
          textColor: CustomColors.productNormal,
          shadowColor: CustomColors.productBorderNormal,
        ),
      ],
    );
  }
}