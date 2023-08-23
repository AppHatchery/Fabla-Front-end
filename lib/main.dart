import 'package:audio_diaries_flutter/screens/diary/presentation/cubit/diary/summary_cubit.dart';
import 'package:audio_diaries_flutter/screens/diary/presentation/pages/new_diary.dart';
import 'package:audio_diaries_flutter/screens/home/presentation/pages/homepage.dart';
import 'package:audio_diaries_flutter/theme/custom_colors.dart';
import 'package:audio_diaries_flutter/theme/custom_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'core/database/object_box.dart';
import 'screens/diary/data/diary.dart';
import 'screens/diary/presentation/cubit/prompt/prompt_cubit.dart';
import 'screens/diary/presentation/pages/diaries.dart';
import 'screens/diary/presentation/pages/diarysummary.dart';
import 'screens/home/presentation/cubit/cubit/home_cubit.dart';
import 'services/diary_init.dart';

//Global variables
late ObjectBox objectbox;
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  objectbox = await ObjectBox.create();
  await diaryInit();
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
        return MultiBlocProvider(
            providers: [
              BlocProvider<HomeCubit>(
                create: (context) => HomeCubit(),
              ),
              BlocProvider<PromptCubit>(create: (context) => PromptCubit()),
              BlocProvider<SummaryCubit>(create: (context) => SummaryCubit()),
            ],
            child: MaterialApp(
              title: 'Audio Diaries',
              theme: ThemeData(
                  primaryColor: CustomColors.productNormal, useMaterial3: true),
              home: child,
              debugShowCheckedModeBanner: false,
              onGenerateRoute: (settings) {
                switch (settings.name) {
                  case "/NewDiaryPage":
                    {
                      final Diary diary = settings.arguments as Diary;
                      return MaterialPageRoute(
                          builder: (context) => NewDiaryPage(
                                diary: diary,
                              ));
                    }
                  case "/DiarySummaryPage":
                    {
                      final Diary diary = settings.arguments as Diary;
                      return MaterialPageRoute(
                          builder: (context) => DiarySummaryPage(
                                diary: diary,
                              ));
                    }
                  default:
                    return MaterialPageRoute(builder: (context) => const Hub());
                }
              },
            ));
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
