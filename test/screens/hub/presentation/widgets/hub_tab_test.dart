import 'package:audio_diaries_flutter/screens/hub/presentation/widgets/hub_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const labels = ['Study', 'History', 'Settings'];

/// Pumps a bottom navigation bar built like the hub's, with labels drawn at
/// [textScale] (2.0 is the iOS cap, 1.5 Android's) on a [width]-wide phone.
Future<void> pumpTabBar(
  WidgetTester tester, {
  required double textScale,
  double width = 320,
  bool useHubTab = true,
}) async {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: DefaultTabController(
        length: labels.length,
        child: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: Scaffold(
              bottomNavigationBar: Material(
                child: Builder(
                  builder: (context) => TabBar(
                    tabs: [
                      for (final label in labels)
                        useHubTab
                            ? hubTab(context,
                                icon: const Icon(Icons.history), label: label)
                            : Tab(icon: const Icon(Icons.history), text: label),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// True when every label is drawn entirely inside its own tab.
bool labelsFitInTabs(WidgetTester tester) {
  final tabs = tester.widgetList(find.byType(Tab)).toList();
  for (var i = 0; i < labels.length; i++) {
    final tabRect = tester.getRect(find.byWidget(tabs[i]));
    final labelRect = tester.getRect(find.text(labels[i]));
    // A label cut short by the fade overflow is wider than its paragraph.
    final paragraph =
        tester.renderObject<RenderParagraph>(find.text(labels[i]));
    if (paragraph.getMaxIntrinsicWidth(double.infinity) >
        paragraph.size.width + 0.5) {
      return false;
    }
    if (labelRect.left < tabRect.left - 0.5 ||
        labelRect.right > tabRect.right + 0.5 ||
        labelRect.top < tabRect.top - 0.5 ||
        labelRect.bottom > tabRect.bottom + 0.5) {
      return false;
    }
  }
  return true;
}

void main() {
  for (final scale in [1.0, 1.5, 2.0]) {
    testWidgets('labels fit inside their tabs at ${scale}x', (tester) async {
      await pumpTabBar(tester, textScale: scale);
      expect(tester.takeException(), isNull);
      expect(labelsFitInTabs(tester), isTrue);
    });
  }

  testWidgets('tabs keep the default 72pt height at normal text',
      (tester) async {
    await pumpTabBar(tester, textScale: 1.0);
    expect(tester.getSize(find.byType(Tab).first).height, 72);
  });

  testWidgets('plain Tab(text:) fades or clips labels at 2.0x (regression)',
      (tester) async {
    await pumpTabBar(tester, textScale: 2.0, useHubTab: false);
    expect(labelsFitInTabs(tester), isFalse);
  });
}
