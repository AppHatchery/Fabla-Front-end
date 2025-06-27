import 'package:audio_diaries_flutter/main.dart';
import 'package:audio_diaries_flutter/screens/onboarding/domain/entities/participant.dart';
import 'package:audio_diaries_flutter/screens/onboarding/domain/repository/setup_repository.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/pages/active_dates.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/pages/camera_access.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/pages/dynamic_page.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/pages/finish.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/pages/location_access.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/pages/study_login.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/pages/welcome.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/pages/mic_access.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/pages/notification_access.dart';
import 'package:audio_diaries_flutter/services/preference_service.dart';
import 'package:audio_diaries_flutter/services/route_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'route_service_test.mocks.dart';

@GenerateMocks([PreferenceService, SetupRepository, NavigatorObserver])
void main() {
  late RouteService routeService;
  late MockPreferenceService mockPreferenceService;
  late MockSetupRepository mockSetupRepository;
  // late MockNavigatorObserver mockNavigatorObserver; // Will be used later for navigate/navigateBack

  setUp(() {
    mockPreferenceService = MockPreferenceService();
    mockSetupRepository = MockSetupRepository();
    // mockNavigatorObserver = MockNavigatorObserver(); // Will be used later

    // Correctly instantiate RouteService with mocked dependencies
    routeService = RouteService(
      preferenceService: mockPreferenceService,
      setupRepository: mockSetupRepository,
    );
  });

  group('RouteService Tests', () {
    // Tests for getRoute
    group('getRoute', () {
      // Helper to set up common preference mocks
      void setupAllPreferenceMocks({
        List<String>? extraPermissions,
        bool setup = false,
        bool notificationRequested = false,
        bool activeDatesSeen = false,
        bool microphone = false,
        bool location = false,
        bool camera = false,
        bool onboardingComplete = false,
      }) {
        // Default behavior for setBoolPreference, can be overridden if specific test needs to verify its call
        when(mockPreferenceService.setBoolPreference(
                key: 'cold_start', value: true))
            .thenAnswer((_) async => true);

        when(mockPreferenceService.getStringListPreference(
                key: 'extra_permissions'))
            .thenAnswer((_) async => extraPermissions ?? []);
        when(mockPreferenceService.getBoolPreference(key: 'setup'))
            .thenAnswer((_) async => setup);
        when(mockPreferenceService.getBoolPreference(
                key: 'notification_requested'))
            .thenAnswer((_) async => notificationRequested);
        when(mockPreferenceService.getBoolPreference(key: 'active_dates_seen'))
            .thenAnswer((_) async => activeDatesSeen);
        when(mockPreferenceService.getBoolPreference(key: 'microphone'))
            .thenAnswer((_) async => microphone);
        when(mockPreferenceService.getBoolPreference(key: 'location'))
            .thenAnswer((_) async => location);
        when(mockPreferenceService.getBoolPreference(key: 'camera'))
            .thenAnswer((_) async => camera);
        when(mockPreferenceService.getBoolPreference(
                key: 'onboarding_complete'))
            .thenAnswer((_) async => onboardingComplete);
      }

      testWidgets('should return Hub when setup is true',
          (WidgetTester tester) async {
        setupAllPreferenceMocks(setup: true);
        // Participant data is irrelevant if setup is true
        when(mockSetupRepository.getParticipant()).thenReturn(null);

        final widget = await routeService.getRoute();
        expect(widget, isA<Hub>());
        verify(mockPreferenceService.setBoolPreference(
                key: 'cold_start', value: true))
            .called(1);
      });

      testWidgets(
          'should return StudyLogin when participant is null and setup is false',
          (WidgetTester tester) async {
        setupAllPreferenceMocks(setup: false);
        when(mockSetupRepository.getParticipant()).thenReturn(null);

        final widget = await routeService.getRoute();
        expect(widget, isA<StudyLogin>());
        verify(mockPreferenceService.setBoolPreference(
                key: 'cold_start', value: true))
            .called(1);
      });

      testWidgets(
          'should return WelcomePage when participant name is empty and setup is false',
          (WidgetTester tester) async {
        setupAllPreferenceMocks(setup: false);
        when(mockSetupRepository.getParticipant()).thenReturn(Participant(
          id: 1,
          studyCode: 'p1',
          name: '',
        ));

        final widget = await routeService.getRoute();
        expect(widget, isA<WelcomePage>());
        verify(mockPreferenceService.setBoolPreference(
                key: 'cold_start', value: true))
            .called(1);
      });

      testWidgets(
          'should return NotificationAccessPage when notificationAccess is false',
          (WidgetTester tester) async {
        setupAllPreferenceMocks(setup: false, notificationRequested: false);
        when(mockSetupRepository.getParticipant()).thenReturn(Participant(
          id: 1,
          studyCode: 'p1',
          name: 'Test',
        ));

        final widget = await routeService.getRoute();
        expect(widget, isA<NotificationAccessPage>());
        verify(mockPreferenceService.setBoolPreference(
                key: 'cold_start', value: true))
            .called(1);
      });

      testWidgets(
          'should return MicAccessPage when micAccess is false and required',
          (WidgetTester tester) async {
        setupAllPreferenceMocks(
            setup: false,
            notificationRequested: true,
            microphone: false,
            extraPermissions: ['microphone']);
        when(mockSetupRepository.getParticipant()).thenReturn(Participant(
          id: 1,
          studyCode: 'p1',
          name: 'Test',
        ));

        final widget = await routeService.getRoute();
        expect(widget, isA<MicAccessPage>());
        verify(mockPreferenceService.setBoolPreference(
                key: 'cold_start', value: true))
            .called(1);
      });

      testWidgets(
          'should return CameraAccess when cameraAccess is false and required',
          (WidgetTester tester) async {
        setupAllPreferenceMocks(
            setup: false,
            notificationRequested: true,
            microphone:
                true, // Assuming mic is handled or not required if camera is next
            camera: false,
            extraPermissions: [
              'microphone',
              'camera'
            ] // Mic could be optional here too
            );
        when(mockSetupRepository.getParticipant()).thenReturn(Participant(
          id: 1,
          studyCode: 'p1',
          name: 'Test',
        ));

        final widget = await routeService.getRoute();
        expect(widget, isA<CameraAccess>());
        verify(mockPreferenceService.setBoolPreference(
                key: 'cold_start', value: true))
            .called(1);
      });

      testWidgets(
          'should return LocationAccess when locationAccess is false and required',
          (WidgetTester tester) async {
        setupAllPreferenceMocks(
            setup: false,
            notificationRequested: true,
            microphone: true,
            camera: true,
            location: false,
            extraPermissions: ['microphone', 'camera', 'location']);
        when(mockSetupRepository.getParticipant()).thenReturn(Participant(
          id: 1,
          studyCode: 'p1',
          name: 'Test',
        ));

        final widget = await routeService.getRoute();
        expect(widget, isA<LocationAccess>());
        verify(mockPreferenceService.setBoolPreference(
                key: 'cold_start', value: true))
            .called(1);
      });

      testWidgets(
          'should return DynamicOnBoardingHub when onboardingComplete is false',
          (WidgetTester tester) async {
        setupAllPreferenceMocks(
            setup: false,
            notificationRequested: true,
            microphone: true,
            camera: true,
            location: true,
            onboardingComplete: false,
            extraPermissions: [
              'microphone',
              'camera',
              'location'
            ] // Assuming all prior permissions granted or not in extra_permissions
            );
        when(mockSetupRepository.getParticipant()).thenReturn(Participant(
          id: 1,
          studyCode: 'p1',
          name: 'Test',
        ));

        final widget = await routeService.getRoute();
        expect(widget, isA<DynamicOnBoardingHub>());
        verify(mockPreferenceService.setBoolPreference(
                key: 'cold_start', value: true))
            .called(1);
      });

      testWidgets('should return ActiveDatesPage when activeDatesSeen is false',
          (WidgetTester tester) async {
        setupAllPreferenceMocks(
            setup: false,
            notificationRequested: true,
            microphone: true,
            camera: true,
            location: true,
            onboardingComplete: true,
            activeDatesSeen: false,
            extraPermissions: ['microphone', 'camera', 'location']);
        when(mockSetupRepository.getParticipant()).thenReturn(Participant(
          id: 1,
          studyCode: 'p1',
          name: 'Test',
        ));

        final widget = await routeService.getRoute();
        expect(widget, isA<ActiveDatesPage>());
        verify(mockPreferenceService.setBoolPreference(
                key: 'cold_start', value: true))
            .called(1);
      });

      testWidgets('should return FinishPage as default',
          (WidgetTester tester) async {
        setupAllPreferenceMocks(
            setup: false,
            notificationRequested: true,
            microphone: true,
            camera: true,
            location: true,
            onboardingComplete: true,
            activeDatesSeen: true,
            extraPermissions: ['microphone', 'camera', 'location']);
        when(mockSetupRepository.getParticipant()).thenReturn(Participant(
          id: 1,
          studyCode: 'p1',
          name: 'Test',
        ));

        final widget = await routeService.getRoute();
        expect(widget, isA<FinishPage>());
        verify(mockPreferenceService.setBoolPreference(
                key: 'cold_start', value: true))
            .called(1);
      });

      testWidgets(
          'getRoute should correctly skip optional permissions if not in extra_permissions',
          (WidgetTester tester) async {
        setupAllPreferenceMocks(
          setup: false,
          notificationRequested: true, // Mandatory permission
          microphone:
              false, // This would normally block, but not in extra_permissions
          camera: false, // Same here
          location: false, // And here
          onboardingComplete: false, // Next step after permissions
          extraPermissions: [], // No optional permissions requested
        );
        when(mockSetupRepository.getParticipant()).thenReturn(Participant(
          id: 1,
          studyCode: 'p1',
          name: 'Test Name',
        ));

        final widget = await routeService.getRoute();
        expect(widget,
            isA<DynamicOnBoardingHub>()); // Should go to onboarding if all perms (mandatory + present optional) are met
        verify(mockPreferenceService.setBoolPreference(
                key: 'cold_start', value: true))
            .called(1);
      });
    });

  });
}
