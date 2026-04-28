import 'package:audio_diaries_flutter/theme/components/webview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

Widget buildWidget({
  required String url,
  String? completionJSFunction,
  Function(bool?)? onComplete,
  Function(dynamic)? errorText,
}) {
  return ScreenUtilInit(
    minTextAdapt: true,
    designSize: const Size(390, 844),
    builder: (_, __) => MaterialApp(
      home: Scaffold(
        body: CustomWebViewWidget(
          url: url,
          completionJSFunction: completionJSFunction,
          onComplete: onComplete ?? (_) {},
          errorText: errorText ?? (_) {},
        ),
      ),
    ),
  );
}

void main() {
  // WebViewErrorCard renders Image.asset icons that aren't available in the test
  // bundle. Suppress the resulting FlutterError so the rest of the widget tree —
  // including the Text widgets we assert on — is still built and inspectable.
  setUp(() {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('Unable to load asset')) return;
      originalOnError?.call(details);
    };
  });

  group('invalid URL handling', () {
    testWidgets('shows "Page Not Found" error immediately for a URL with no scheme',
        (tester) async {
      await tester.pumpWidget(buildWidget(url: 'no-scheme-url'));
      await tester.pump();

      // The error is set synchronously in initState — no loading state.
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Page Not Found'), findsOneWidget);
    });

    testWidgets('shows "Page Not Found" error for an empty URL', (tester) async {
      await tester.pumpWidget(buildWidget(url: ''));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Page Not Found'), findsOneWidget);
    });

    testWidgets('does not invoke onComplete for an invalid URL', (tester) async {
      bool? completedValue;

      await tester.pumpWidget(buildWidget(
        url: 'no-scheme-url',
        onComplete: (v) => completedValue = v,
      ));
      await tester.pump();

      expect(completedValue, isNull);
    });

    testWidgets('does not invoke errorText for an invalid URL (error handled internally)',
        (tester) async {
      dynamic capturedErrorText;

      await tester.pumpWidget(buildWidget(
        url: 'no-scheme-url',
        errorText: (v) => capturedErrorText = v,
      ));
      await tester.pump();

      // errorText is only called from _skip(), not from URL validation.
      expect(capturedErrorText, isNull);
    });
  });

  group('completionJSFunction prop', () {
    testWidgets('builds without a completionJSFunction (null)', (tester) async {
      await tester.pumpWidget(buildWidget(url: 'no-scheme-url'));
      await tester.pump();

      // Widget renders error state — no platform exception from missing function.
      expect(tester.takeException(), isNull);
    });

    testWidgets('builds with a completionJSFunction provided', (tester) async {
      await tester.pumpWidget(buildWidget(
        url: 'no-scheme-url',
        completionJSFunction: '(function() { return true; })()',
      ));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('completionJSFunction value is preserved in the widget', (tester) async {
      const jsFunction = '(function() { return true; })()';

      await tester.pumpWidget(buildWidget(
        url: 'no-scheme-url',
        completionJSFunction: jsFunction,
      ));
      await tester.pump();

      final webViewWidget = tester.widget<CustomWebViewWidget>(
        find.byType(CustomWebViewWidget),
      );
      expect(webViewWidget.completionJSFunction, equals(jsFunction));
    });

    testWidgets('null completionJSFunction is preserved in the widget', (tester) async {
      await tester.pumpWidget(buildWidget(url: 'no-scheme-url'));
      await tester.pump();

      final webViewWidget = tester.widget<CustomWebViewWidget>(
        find.byType(CustomWebViewWidget),
      );
      expect(webViewWidget.completionJSFunction, isNull);
    });
  });

  group('loading state', () {
    testWidgets('is not in loading state for an invalid URL', (tester) async {
      await tester.pumpWidget(buildWidget(url: 'no-scheme-url'));
      await tester.pump();

      // loading = false is set synchronously in the else-branch of initState.
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}
