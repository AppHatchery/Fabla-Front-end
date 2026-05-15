
import 'package:alarm/alarm.dart';
import 'package:audio_diaries_flutter/core/usecases/notification_manager.dart';
import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/repository/diary_repository.dart';
import 'package:audio_diaries_flutter/screens/diary/presentation/cubit/bulk_submission/bulk_submission_cubit.dart';
import 'package:audio_diaries_flutter/screens/diary/presentation/cubit/completion/completion_cubit.dart';
import 'package:audio_diaries_flutter/screens/diary/presentation/cubit/diary/diary_cubit.dart';
import 'package:audio_diaries_flutter/screens/diary/presentation/cubit/diary/diary_history_cubit.dart';
import 'package:audio_diaries_flutter/screens/diary/presentation/cubit/diary/summary_cubit.dart';
import 'package:audio_diaries_flutter/screens/diary/presentation/cubit/prompt/prompt_cubit.dart';
import 'package:audio_diaries_flutter/screens/diary/presentation/pages/new_diary.dart';
import 'package:audio_diaries_flutter/screens/home/presentation/pages/homepage.dart';
import 'package:audio_diaries_flutter/screens/hub/presentation/cubit/hub_cubit.dart';
import 'package:audio_diaries_flutter/screens/onboarding/domain/repository/setup_repository.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/cubit/dynamic/dynamic_cubit.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/cubit/login/login_cubit.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/cubit/login/study_login_cubit.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/cubit/setup/setup_cubit.dart';
import 'package:audio_diaries_flutter/screens/settings/cubit/settings_cubit.dart';
import 'package:audio_diaries_flutter/screens/settings/presentation/settings.dart';
import 'package:audio_diaries_flutter/services/crashlytics_service.dart';
import 'package:audio_diaries_flutter/services/pendo_service.dart';
import 'package:audio_diaries_flutter/services/route_service.dart';
import 'package:audio_diaries_flutter/theme/custom_colors.dart';
import 'package:audio_diaries_flutter/theme/dialogs/bottom_modals.dart';
import 'package:camera/camera.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemChrome, SystemUiOverlayStyle, SystemUiMode;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pendo_sdk/pendo_sdk.dart';
import 'package:rive/rive.dart' show RiveNative;
import 'dart:io' show Platform;

import 'core/database/object_box.dart';
import 'firebase_options.dart';
import 'screens/diary/data/diary.dart';
import 'screens/diary/presentation/pages/diaries.dart';
import 'screens/diary/presentation/pages/diarysummary.dart';
import 'screens/home/presentation/cubit/cubit/home_cubit.dart';
import 'services/notification_service.dart';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:audio_diaries_flutter/core/notifications/controllers/notifications_controller.dart';

//Global variables
late ObjectBox objectbox;
NotificationsController notificationController = NotificationsController();
late List<CameraDescription> cameras;
void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(
      widgetsBinding: widgetsBinding); // Start Splash Screen
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await CrashlyticsService().initialize();
  objectbox = await ObjectBox.create();
  cameras = await availableCameras();
  await RiveNative.init();
  await Alarm.init();
  await NotificationService.init();
  await PendoService.init();
  final route = await RouteService().getRoute();
  await _configureFirebase();
  runApp(MyApp(
    route: route,
  ));
  FlutterNativeSplash.remove(); // Close Splash Screen
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  notificationController = NotificationsController();
  await notificationController.messageHandler(message);
}

Future<void> _configureFirebase() async {
  await Firebase.initializeApp();
  await notificationController.initialize(); // Ensure this waits
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
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
    CrashlyticsService().setUserIdentifier();
    _route = widget.route;
    super.initState();
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
                BlocProvider<DynamicCubit>(create: (context) => DynamicCubit()),
                BlocProvider<HubCubit>(create: (context) => HubCubit()),
                BlocProvider<SettingsCubit>(
                    create: (context) => SettingsCubit()),
                BlocProvider<BulkSubmissionCubit>(
                    create: (context) => BulkSubmissionCubit()),
              ],
              child: PendoActionListener(
                child: MaterialApp(
                  title: 'Fabla',
                  theme: ThemeData(
                      primaryColor: CustomColors.productNormal,
                      useMaterial3: true),
                  home: child,
                  debugShowCheckedModeBanner: false,
                  navigatorObservers: [
                    PendoNavigationObserver(),
                    CustomNavigatorObserver()
                  ],
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
                            ),
                            settings: RouteSettings(name: "/NewDiaryPage"),
                          );
                        }
                      case "/DiarySummaryPage":
                        {
                          final DiaryModel diary =
                              settings.arguments as DiaryModel;
                          return MaterialPageRoute(
                            builder: (context) => DiarySummaryPage(
                              diary: diary,
                            ),
                            settings: RouteSettings(name: "/DiarySummaryPage"),
                          );
                        }
                      default:
                        return MaterialPageRoute(
                          builder: (context) => const Hub(),
                          settings: RouteSettings(name: "/Hub"),
                        );
                    }
                  },
                ),
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
  // used to refresh the page for updating
  Key key = UniqueKey();
  final ValueNotifier<bool?> completeNotifier = ValueNotifier(null);

  late HubCubit cubit;
  late TabController tabController;
  List<Tab> navigationBars = [];
  static const pages = [
    HomePage(),
    DiariesPage(),
    Settings(),
  ];

  final isAndroid = Platform.isAndroid;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    // Removing the dark bars that come with the safe area
    if (Platform.isAndroid) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.white,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
          systemNavigationBarContrastEnforced: false,
        ),
      );
    }
    cubit = BlocProvider.of<HubCubit>(context);
    tabController = TabController(length: pages.length, vsync: this);
    startPendo();
    _makeNavBars();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationManager()
          .scheduleAdditional(); // Ensure that this also trigger when the app has just started
      NotificationManager().scheduleUserReminders(); // Schedule user reminders
    });
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
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return KeyedSubtree(
      key: key,
      child: BlocConsumer<HubCubit, HubState>(
        listener: (context, state) {
          if (state is HubUpdating) {
            showUpdateDialog();
          } else if (state is HubUpdated) {
            completeUpdate(state.complete);
          } else if (state is HubRefreshing) {
            refresh();
          }
        },
        builder: (context, state) {
          return Scaffold(
            body: SafeArea(
              top: false,
              bottom: false,
              child: TabBarView(
                physics: const NeverScrollableScrollPhysics(),
                controller: tabController,
                children: pages,
              ),
            ),
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
                  padding: EdgeInsets.only(
                    top: 8,
                    bottom: bottomPadding > 0 ? bottomPadding : (isIos ? 34 : 8),
                  ),
                  dividerColor: Colors.transparent,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  startPendo() async {
    final repository = SetupRepository();
    final participant = repository.getParticipant();
    final experiment = repository.getExperiment();
    await PendoService.start(
        participant!.studyCode.toString(), experiment.login);
  }

  _makeNavBars() {
    final repository = DiaryRepository();
    final diaries = repository.getAllDiaries();
    final count = diaries
        .where((element) => element.status == DiaryStatus.complete)
        .length;

    if (navigationBars.isNotEmpty) navigationBars.clear();

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

  void completeUpdate(bool completed) {
    if (mounted) {
      setState(() => completeNotifier.value = completed);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pop(context);
        }
      }).then((_) {
        Future.delayed(const Duration(seconds: 1), () => refresh());
      });
    }
  }

  void refresh() {
    if (mounted) {
      setState(() {
        key = UniqueKey();
        _makeNavBars();
      });
    }
  }

  showUpdateDialog() {
    if (mounted) {
      setState(() {
        completeNotifier.value = null;
      });
    }
    showModalBottomSheet(
        context: context,
        isDismissible: false,
        enableDrag: false,
        useSafeArea: true,
        routeSettings: RouteSettings(name: "/UpdateModal"),
        builder: (context) => Wrap(
              children: [
                BottomUpdateModal(
                  completeNotifier: completeNotifier,
                ),
              ],
            ));
  }
}
