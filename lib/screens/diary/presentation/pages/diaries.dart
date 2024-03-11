import 'package:audio_diaries_flutter/screens/diary/presentation/widgets/diary_calender.dart';
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

enum Calendar { list, calendar }

class _DiaryPageState extends State<DiariesPage> with TickerProviderStateMixin {
  late TabController _tabController;
  DateTime startDate = DateTime.now();

  @override
  void initState() {
    PendoService.track("HistoryTab", {"study_day": "${DateTime.now()}"});
    _tabController = TabController(length: 2, vsync: this);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: CustomColors.fillNormal,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          centerTitle: true,
          title: TabBar(
            controller: _tabController,
            labelColor: CustomColors.productNormalActive,
            labelStyle: CustomTypography().titleLarge(),
            unselectedLabelStyle: CustomTypography().titleLarge(),
            unselectedLabelColor: CustomColors.textTertiaryContent,
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorWeight: 3,
            indicatorColor: CustomColors.productNormalActive,
            tabs: const [Tab(text: "List"), Tab(text: "Calendar")],
            splashFactory: NoSplash.splashFactory,
          ),
          backgroundColor: CustomColors.fillNormal,
        ),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 12.0),
          child: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: const [DiaryList(), DiaryCalender()]),
        ));
  }
}
