import 'package:audio_diaries_flutter/screens/settings/presentation/pages/quickstart_video.dart';
import 'package:audio_diaries_flutter/theme/custom_colors.dart';
import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:flutter/material.dart';

class QuickstartPage extends StatelessWidget {
  const QuickstartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColors.fillNormal,
      appBar: AppBar(
        backgroundColor: CustomColors.fillNormal,
        title: Text(
          'Fabla Quickstart',
          style: CustomTypography().titleLarge(),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        shape: const Border(
          bottom: BorderSide(
            color: CustomColors.productBorderNormal,
            width: 2,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              tile(
                  title: 'Your Study Page',
                  description: 'Daily goal and entries',
                  imagePath: 'assets/images/quickstart/home.png',
                  onTap: () => _navigateToVideoPage(context, 'study')),
              tile(
                  title: 'History',
                  description: 'Entry status and submitting',
                  imagePath: 'assets/images/quickstart/history.png',
                  onTap: () => _navigateToVideoPage(context, 'history')),
              tile(
                  title: 'Incentives',
                  description: 'What your study pays',
                  imagePath: 'assets/images/quickstart/incentives.png',
                  onTap: () => _navigateToVideoPage(context, 'incentives')),
              tile(
                  title: 'Calendar',
                  description: 'Scheduled entries and streak',
                  imagePath: 'assets/images/quickstart/calendar.png',
                  onTap: () => _navigateToVideoPage(context, 'calendar')),
              tile(
                  title: 'Settings',
                  description: 'Details, contact, reminders',
                  imagePath: 'assets/images/quickstart/settings.png',
                  onTap: () => _navigateToVideoPage(context, 'settings')),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToVideoPage(BuildContext context, String videoName) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => QuickstartVideoPage(videoName: videoName)),
    );
  }

  Widget tile(
      {required String title,
      required String description,
      required String imagePath,
      required void Function()? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
        decoration: ShapeDecoration(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(
                    color: CustomColors.productBorderNormal, width: 1)),
            color: Colors.white),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: 14,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: Image.asset(imagePath),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 3,
                children: [
                  Text(
                    title,
                    style: CustomTypography().bodyLarge(
                        color: CustomColors.textNormalContent,
                        weight: FontWeight.w500),
                  ),
                  Text(
                    description,
                    style: CustomTypography()
                        .bodyMedium(color: CustomColors.textTertiaryContent),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 24,
              color: CustomColors.midGrey,
              applyTextScaling: true,
            ),
          ],
        ),
      ),
    );
  }
}
