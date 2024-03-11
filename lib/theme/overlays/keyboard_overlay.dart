import 'package:audio_diaries_flutter/theme/custom_colors.dart';
import 'package:flutter/cupertino.dart';

class CustomKeyboardOverlay extends StatelessWidget {
  const CustomKeyboardOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: CustomColors.fillWhite,
      width: double.infinity,
      child: Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  FocusScope.of(context).unfocus();
                },
                child: const Icon(
                  CupertinoIcons.checkmark_alt,
                  color: CupertinoColors.systemGrey,
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  FocusScope.of(context).unfocus();
                },
                child: const Icon(
                  CupertinoIcons.keyboard_chevron_compact_down,
                  color: CupertinoColors.systemGrey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
