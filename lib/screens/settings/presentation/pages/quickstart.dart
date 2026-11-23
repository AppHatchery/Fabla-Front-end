import 'package:audio_diaries_flutter/core/usecases/font_scaler_detector_and_adjuster.dart';
import 'package:audio_diaries_flutter/screens/settings/presentation/widgets/quickSartHelperTile.dart';
import 'package:audio_diaries_flutter/screens/settings/presentation/pages/quickstart_video.dart';
import 'package:audio_diaries_flutter/theme/custom_colors.dart';
import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';

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
          icon: const FittedBox(
            child: Icon(
              applyTextScaling: true,
              Icons.arrow_back_rounded,
              size: 32,
            ),
          ),
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
              Tile(
                  title: 'Your Study Page',
                  description: 'Daily goal and entries',
                  imagePath: 'assets/images/quickstart/home.png',
                  onTap: () => _navigateToVideoPage(context, 'study')),
              Tile(
                  title: 'History',
                  description: 'Entry status and submitting',
                  imagePath: 'assets/images/quickstart/history.png',
                  onTap: () => _navigateToVideoPage(context, 'history')),
              Tile(
                  title: 'Incentives',
                  description: 'What your study pays',
                  imagePath: 'assets/images/quickstart/incentives.png',
                  onTap: () => _navigateToVideoPage(context, 'incentives')),
              Tile(
                  title: 'Calendar',
                  description: 'Scheduled entries and streak',
                  imagePath: 'assets/images/quickstart/calendar.png',
                  onTap: () => _navigateToVideoPage(context, 'calendar')),
              Tile(
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
}
