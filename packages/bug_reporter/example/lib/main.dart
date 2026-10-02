import 'package:bug_reporter/bug_reporter.dart';
import 'package:flutter/material.dart';

final navigatorKey = GlobalKey<NavigatorState>();
final messengerKey = GlobalKey<ScaffoldMessengerState>();

void main() {
  BugReporter.init(BugReporterConfig(
    navigatorKey: navigatorKey,
    messengerKey: messengerKey,
    showReportButton: true,
    routeNames: const {'/': 'Home'},
  ));
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'bug_reporter example',
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: messengerKey,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      builder: (context, child) =>
          BugReportScope(child: child ?? const SizedBox.shrink()),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('bug_reporter example')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Tap the red bug button to file a report.'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  Breadcrumbs.instance.custom('example_button_pressed'),
              child: const Text('Drop a breadcrumb'),
            ),
          ],
        ),
      ),
    );
  }
}
