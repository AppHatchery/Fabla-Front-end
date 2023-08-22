import 'package:audio_diaries_flutter/screens/diary/presentation/pages/diarycompletion.dart';
import 'package:audio_diaries_flutter/screens/diary/presentation/pages/diarysummary.dart';
import 'package:audio_diaries_flutter/screens/home/presentation/pages/homepage.dart';
import 'package:audio_diaries_flutter/theme/custom_colors.dart';
import 'package:audio_diaries_flutter/theme/custom_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'screens/diary/presentation/pages/diaries.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    return ScreenUtilInit(
      minTextAdapt: true,
      designSize: Size(width, height),
      builder: (context, child) {
        return MaterialApp(
          title: 'Audio Diaries',
          theme: ThemeData(
              primaryColor: CustomColors.productNormal, useMaterial3: true),
          home: child,
          debugShowCheckedModeBanner: false,
        );
      },
      child: const Hub(),
    );
  }
}

class Hub extends StatefulWidget {
  const Hub({super.key});

  @override
  State<Hub> createState() => _HubState();
}

class _HubState extends State<Hub> with SingleTickerProviderStateMixin {
  late TabController tabController;
  static const pages = [
    HomePage(),
    DiariesPage(),
    DiariesPage(),
  ];

  @override
  void initState() {
    tabController = TabController(length: pages.length, vsync: this);
    super.initState();
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TabBarView(controller: tabController, children: pages),
      bottomNavigationBar: Material(
        color: CustomColors.fillWhite,
        child: TabBar(
          controller: tabController,
          tabs: navigationBars,
          labelColor: CustomColors.productNormal,
          unselectedLabelColor: Colors.black,
          indicatorColor: Colors.transparent,
          indicatorWeight: 2,
          indicator: null,
        ),
      ),
    );
  }

  static const navigationBars = <Tab>[
    Tab(
      icon: Icon(CustomIcons.home),
      text: "Home",
    ),
    Tab(
      icon: Icon(CustomIcons.albumOutline),
      text: "Diary",
    ),
    Tab(
      icon: Icon(Icons.settings),
      text: "Settings",
    ),
  ];
}
