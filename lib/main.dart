import 'dart:ui';

import 'package:audio_diaries_flutter/core/usecases/notification_manager.dart';
import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/repository/diary_repository.dart';
import 'package:audio_diaries_flutter/screens/diary/presentation/cubit/completion/completion_cubit.dart';
import 'package:audio_diaries_flutter/screens/diary/presentation/cubit/diary/diary_cubit.dart';
import 'package:audio_diaries_flutter/screens/diary/presentation/cubit/diary/diary_history_cubit.dart';
import 'package:audio_diaries_flutter/screens/diary/presentation/cubit/diary/summary_cubit.dart';
import 'package:audio_diaries_flutter/screens/diary/presentation/cubit/prompt/prompt_cubit.dart';
import 'package:audio_diaries_flutter/screens/diary/presentation/pages/new_diary.dart';
import 'package:audio_diaries_flutter/screens/home/presentation/pages/homepage.dart';
import 'package:audio_diaries_flutter/screens/onboarding/domain/repository/setup_repository.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/cubit/dynamic/dynamic_cubit.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/cubit/login/login_cubit.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/cubit/login/study_login_cubit.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/cubit/setup/setup_cubit.dart';
import 'package:audio_diaries_flutter/screens/settings/presentation/settings.dart';
import 'package:audio_diaries_flutter/services/pendo_service.dart';
import 'package:audio_diaries_flutter/services/route_service.dart';
import 'package:audio_diaries_flutter/theme/custom_colors.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:io' show Platform;

import 'core/database/object_box.dart';
import 'firebase_options.dart';
import 'screens/diary/data/diary.dart';
import 'screens/diary/presentation/pages/diaries.dart';
import 'screens/diary/presentation/pages/diarysummary.dart';
import 'screens/home/presentation/cubit/cubit/home_cubit.dart';
import 'services/notification_service.dart';

//Global variables
late ObjectBox objectbox;
void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(
      widgetsBinding: widgetsBinding); // Start Splash Screen
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!kDebugMode);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!kDebugMode);
    return true;
  };
  objectbox = await ObjectBox.create();
  //await configureAmplify();
  await NotificationService.init();
  await PendoService.init();
  final route = await RouteService().getRoute();
  runApp(MyApp(
    route: route,
  ));
  FlutterNativeSplash.remove(); // Close Splash Screen
}

class MyApp extends StatefulWidget {
  final Widget route;
  const MyApp({super.key, required this.route});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final RouteService routeService = RouteService();
  late Widget _route;
  @override
  initState() {
    NotificationService.setListeners();
    _route = widget.route;
    // final repo = SetupRepository();
    // repo.createProtocol();
    super.initState();
    // initPlatformState();
  }

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
                BlocProvider<SummaryCubit>(create: (context) => SummaryCubit()),
                BlocProvider<LoginCubit>(create: (context) => LoginCubit()),
                BlocProvider<StudyLoginCubit>(
                    create: (context) => StudyLoginCubit()),
                BlocProvider<SetupCubit>(create: (context) => SetupCubit()),
                BlocProvider<DiaryCubit>(create: (context) => DiaryCubit()),
                BlocProvider<PromptCubit>(create: (context) => PromptCubit()),
                BlocProvider<DiaryHistoryCubit>(
                    create: (context) => DiaryHistoryCubit()),
                BlocProvider<CompletionCubit>(
                    create: (context) => CompletionCubit()),
                BlocProvider<DynamicCubit>(create: (context) => DynamicCubit())
              ],
              child: MaterialApp(
                title: 'Audio Diaries',
                theme: ThemeData(
                    primaryColor: CustomColors.productNormal,
                    useMaterial3: true),
                home: child,
                debugShowCheckedModeBanner: false,
                onGenerateRoute: (settings) {
                  switch (settings.name) {
                    case "/NewDiaryPage":
                      {

                        final Map arguments = settings.arguments as Map;
                        final DiaryModel diary =
                            arguments['diary'] as DiaryModel;
                        final int? index = arguments['index'] as int?;
                        return MaterialPageRoute(
                            builder: (context) => NewDiaryPage(
                                  diary: diary,
                                  index: index,
                                ));
                      }
                    case "/DiarySummaryPage":
                      {
                        final DiaryModel diary =
                            settings.arguments as DiaryModel;
                        return MaterialPageRoute(
                            builder: (context) => DiarySummaryPage(
                                  diary: diary,
                                ));
                      }
                    default:
                      return MaterialPageRoute(
                          builder: (context) => const Hub());
                  }
                },
              ));
        },
        child: _route);
  }
}

class Hub extends StatefulWidget {
  const Hub({super.key});

  @override
  State<Hub> createState() => _HubState();
}

class _HubState extends State<Hub>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController tabController;
  List<Tab> navigationBars = [];
  static const pages = [
    HomePage(),
    DiariesPage(),
    Settings(),
  ];

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    tabController = TabController(length: pages.length, vsync: this);
    startPendo();
    _makeNavBars();
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      NotificationManager().scheduleAdditional();
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {
    final isIos = Platform.isIOS;
    return Scaffold(
      body: TabBarView(
          physics: const NeverScrollableScrollPhysics(),
          controller: tabController,
          children: pages),
      bottomNavigationBar: Material(
        color: CustomColors.fillWhite,
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(
                color: CustomColors.productBorderNormal,
                width: 1.0,
              ),
            ),
          ),
          child: TabBar(
            controller: tabController,
            tabs: navigationBars,
            labelColor: CustomColors.productNormal,
            unselectedLabelColor: Colors.black,
            indicatorColor: Colors.transparent,
            indicatorWeight: 2,
            indicator: null,
            padding: EdgeInsets.only(bottom: isIos ? 34 : 0),
            dividerColor: Colors.transparent,
          ),
        ),
      ),
    );
  }

  startPendo() async {
    final repository = SetupRepository();
    final participant = repository.getParticipant();
    final experiment = repository.getExperiment();
    await PendoService.start(participant!.studyCode.toString(), experiment.login);
  }

  _makeNavBars() {
    final repository = DiaryRepository();
    final diaries = repository.getAllDiaries();
    final count = diaries
        .where((element) => element.status == DiaryStatus.complete)
        .length;

    navigationBars.addAll(<Tab>[
      const Tab(
        icon: Icon(CupertinoIcons.text_badge_checkmark),
        text: "Study",
      ),
      Tab(
        icon: Badge(
          backgroundColor: CustomColors.warningActive,
          textColor: CustomColors.fillWhite,
          label: Text(count.toString()),
          isLabelVisible: count > 0,
          child: const Icon(Icons.history),
        ),
        text: "History",
      ),
      const Tab(
        icon: Icon(Icons.settings_outlined),
        text: "Settings",
      ),
    ]);
  }
}
