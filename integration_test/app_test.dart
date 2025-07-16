import 'package:audio_diaries_flutter/core/database/object_box.dart';
import 'package:audio_diaries_flutter/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:alarm/alarm.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:camera/camera.dart';
import 'package:audio_diaries_flutter/firebase_options.dart';
import 'package:audio_diaries_flutter/services/notification_service.dart';
import 'package:audio_diaries_flutter/services/pendo_service.dart';
import 'package:audio_diaries_flutter/services/route_service.dart';
import 'helpers/onboarding_flow.dart';
import 'helpers/home_flow.dart';
import 'helpers/history_flow.dart';
import 'helpers/settings_flow.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    app.objectbox = await ObjectBox.create();
    app.cameras = await availableCameras();
    await Alarm.init();
    await NotificationService.init();
    await PendoService.init();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  });

  tearDownAll(() async {
    app.objectbox.store.close();
  });

  Future<void> pumpAppWithRoute(WidgetTester tester) async {
    final route = await RouteService().getRoute();
    await tester.pumpWidget(app.MyApp(route: route));
  }

  group('End to End Test', () {
    testWidgets('Onboarding flow Test', (tester) async {
      await pumpAppWithRoute(tester);
      await tester.pumpAndSettle();
      await onboardingFlow(tester);
    });

    testWidgets('Home flow Test', (tester) async {
      await pumpAppWithRoute(tester);
      await tester.pump();
      await homeFlow(tester);
    });

    testWidgets('History flow Test', (tester) async {
      await pumpAppWithRoute(tester);
      await tester.pump();
      await historyFlow(tester);
    });

    testWidgets('Settings flow Test', (tester) async {
      await pumpAppWithRoute(tester);
      await tester.pump();
      await settingsFlow(tester);
    });
  });
}
