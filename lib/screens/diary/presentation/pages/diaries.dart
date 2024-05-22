import 'package:audio_diaries_flutter/screens/diary/presentation/widgets/diary_list.dart';
import 'package:audio_diaries_flutter/services/pendo_service.dart';
import 'package:flutter/material.dart';

import '../../../../theme/custom_colors.dart';
import '../../../../theme/custom_typography.dart';

class DiariesPage extends StatefulWidget {
  const DiariesPage({super.key});

  @override
  State<DiariesPage> createState() => _DiaryPageState();
}

class _DiaryPageState extends State<DiariesPage> {
  DateTime startDate = DateTime.now();

  @override
  void initState() {
    PendoService.track("HistoryTab", {"study_day": "${DateTime.now()}"});
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: CustomColors.fillNormal,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          centerTitle: true,
          title: Text(
            "History",
            style: CustomTypography()
                .titleLarge(color: CustomColors.textNormalContent),
          ),
          backgroundColor: CustomColors.fillNormal,
          scrolledUnderElevation: 0.0,
        ),
        body: const Padding(
          padding: EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 12.0),
          child: DiaryList(),
        ));
  }
}
