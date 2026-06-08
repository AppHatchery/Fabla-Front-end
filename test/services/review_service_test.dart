import 'package:audio_diaries_flutter/services/preference_service.dart';
import 'package:audio_diaries_flutter/services/review_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockInAppReview extends Mock implements InAppReview {}

void main() {
  late MockInAppReview mockReview;
  late InAppReviewService service;

  setUp(() {
    mockReview = MockInAppReview();
    SharedPreferences.setMockInitialValues({});
    service = InAppReviewService(
      inAppReview: mockReview,
      prefs: PreferenceService(),
    );
  });

  group('recordActiveDay', () {
    test('stores today when prefs are empty', () async {
      await service.recordActiveDay();

      final prefs = await SharedPreferences.getInstance();
      final days = prefs.getStringList('review_active_days');
      expect(days, hasLength(1));
    });

    test('does not add a duplicate when called twice on the same day', () async {
      await service.recordActiveDay();
      await service.recordActiveDay();

      final prefs = await SharedPreferences.getInstance();
      final days = prefs.getStringList('review_active_days');
      expect(days, hasLength(1));
    });

    test('appends today when prior dates are already stored', () async {
      SharedPreferences.setMockInitialValues({
        'review_active_days': ['2026-01-01', '2026-01-02'],
      });
      service = InAppReviewService(
        inAppReview: mockReview,
        prefs: PreferenceService(),
      );

      await service.recordActiveDay();

      final prefs = await SharedPreferences.getInstance();
      final days = prefs.getStringList('review_active_days')!;
      expect(days, hasLength(3));
      expect(days.contains('2026-01-01'), isTrue);
      expect(days.contains('2026-01-02'), isTrue);
    });

    test('does not append today if it is already in a pre-populated list',
        () async {
      final today = _todayKey();
      SharedPreferences.setMockInitialValues({
        'review_active_days': ['2026-01-01', today],
      });
      service = InAppReviewService(
        inAppReview: mockReview,
        prefs: PreferenceService(),
      );

      await service.recordActiveDay();

      final prefs = await SharedPreferences.getInstance();
      final days = prefs.getStringList('review_active_days');
      expect(days, hasLength(2));
    });
  });

  group('maybeRequestReview', () {
    test('does nothing when review has already been requested', () async {
      SharedPreferences.setMockInitialValues({
        'review_requested': true,
        'review_active_days': _daysAgo(10),
      });
      service = InAppReviewService(
        inAppReview: mockReview,
        prefs: PreferenceService(),
      );

      await service.maybeRequestReview();

      verifyNever(() => mockReview.isAvailable());
      verifyNever(() => mockReview.requestReview());
    });

    test('does nothing when active day count is below the threshold', () async {
      SharedPreferences.setMockInitialValues({
        'review_active_days': _daysAgo(9),
      });
      service = InAppReviewService(
        inAppReview: mockReview,
        prefs: PreferenceService(),
      );

      await service.maybeRequestReview();

      verifyNever(() => mockReview.isAvailable());
      verifyNever(() => mockReview.requestReview());
    });

    test('does nothing when threshold is met but review is unavailable',
        () async {
      SharedPreferences.setMockInitialValues({
        'review_active_days': _daysAgo(10),
      });
      service = InAppReviewService(
        inAppReview: mockReview,
        prefs: PreferenceService(),
      );
      when(() => mockReview.isAvailable()).thenAnswer((_) async => false);

      await service.maybeRequestReview();

      verify(() => mockReview.isAvailable()).called(1);
      verifyNever(() => mockReview.requestReview());

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('review_requested'), isNull);
    });

    test('requests review and sets flag when threshold is met and available',
        () async {
      SharedPreferences.setMockInitialValues({
        'review_active_days': _daysAgo(10),
      });
      service = InAppReviewService(
        inAppReview: mockReview,
        prefs: PreferenceService(),
      );
      when(() => mockReview.isAvailable()).thenAnswer((_) async => true);
      when(() => mockReview.requestReview()).thenAnswer((_) async {});

      await service.maybeRequestReview();

      verify(() => mockReview.requestReview()).called(1);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('review_requested'), isTrue);
    });

    test('does not request review a second time after flag is set', () async {
      SharedPreferences.setMockInitialValues({
        'review_active_days': _daysAgo(10),
      });
      service = InAppReviewService(
        inAppReview: mockReview,
        prefs: PreferenceService(),
      );
      when(() => mockReview.isAvailable()).thenAnswer((_) async => true);
      when(() => mockReview.requestReview()).thenAnswer((_) async {});

      await service.maybeRequestReview();
      await service.maybeRequestReview();

      verify(() => mockReview.requestReview()).called(1);
    });

    test('requests review when active days exceed the threshold', () async {
      SharedPreferences.setMockInitialValues({
        'review_active_days': _daysAgo(15),
      });
      service = InAppReviewService(
        inAppReview: mockReview,
        prefs: PreferenceService(),
      );
      when(() => mockReview.isAvailable()).thenAnswer((_) async => true);
      when(() => mockReview.requestReview()).thenAnswer((_) async {});

      await service.maybeRequestReview();

      verify(() => mockReview.requestReview()).called(1);
    });
  });
}

String _todayKey() {
  final now = DateTime.now();
  return '${now.year}-'
      '${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';
}

List<String> _daysAgo(int count) {
  return List.generate(count, (i) {
    final d = DateTime.now().subtract(Duration(days: i + 1));
    return '${d.year}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  });
}
