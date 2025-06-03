import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rive/rive.dart';

// Mock Rive widget to replace actual Rive animations during tests
class MockRiveWidget extends StatelessWidget {
  final String asset;
  final Function(Artboard)? onInit;
  final BoxFit fit;

  const MockRiveWidget({
    super.key,
    required this.asset,
    this.onInit,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    // Return a simple colored container instead of the actual Rive animation
    return Container(
      color: Colors.grey[300],
      child: Center(
        child: Text('Mock Rive: $asset'),
      ),
    );
  }
}

// Create a test helper to replace Rive animations
class TestRiveHelper {
  static Widget createMockRive({
    required String asset,
    Function(Artboard)? onInit,
    BoxFit fit = BoxFit.cover,
  }) {
    return MockRiveWidget(
      asset: asset,
      onInit: onInit,
      fit: fit,
    );
  }
}

// Extension to make it easier to use mock Rive in tests
extension RiveTestExtension on WidgetTester {
  Future<void> pumpRiveWidget(Widget widget) async {
    // Set up the widget binding
    TestWidgetsFlutterBinding.ensureInitialized();

    // Pump the widget
    await pumpWidget(widget);

    // Wait for any animations
    await pump();
    await pump(const Duration(milliseconds: 500));

    // Process any pending platform messages
    await pumpAndSettle();
  }
}
