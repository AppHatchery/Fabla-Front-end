import 'package:flutter/material.dart';

import '../custom_colors.dart';
import 'fabio.dart';

/// A developer page for trying every expression, gesture, prop and preset
/// choreography. Not linked from the app; push it from a debug menu or run
/// it on its own.
class FabioPlaygroundPage extends StatefulWidget {
  const FabioPlaygroundPage({super.key});

  static const presets = [
    'welcome',
    'goal_complete',
    'streak',
    'recording_start',
    'sleepy',
    'peekaboo',
    'personal_best',
  ];

  @override
  State<FabioPlaygroundPage> createState() => _FabioPlaygroundPageState();
}

class _FabioPlaygroundPageState extends State<FabioPlaygroundPage> {
  final _fabio = FabioController(expression: FabioExpression.neutral);
  final _stage = FabioStageController();
  FabioExpression _expression = FabioExpression.neutral;
  String? _lastEvent;

  @override
  void dispose() {
    _fabio.dispose();
    _stage.dispose();
    super.dispose();
  }

  Widget _section(String title, List<Widget> chips) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: CustomColors.productDark)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: chips),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: CustomColors.productLightBackground,
          appBar: AppBar(
            title: const Text('Fabio playground'),
            backgroundColor: CustomColors.productLightBackground,
          ),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 40),
            children: [
              const SizedBox(height: 24),
              Center(
                child: Fabio(size: 150, controller: _fabio, expression: _expression),
              ),
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('Tap him, drag around him, tap fast 4x',
                      style: TextStyle(color: CustomColors.textSecondaryContent)),
                ),
              ),
              _section('Choreographies', [
                for (final p in FabioPlaygroundPage.presets)
                  ActionChip(
                    label: Text(p),
                    onPressed: () => _stage.playAsset('assets/fabio/scripts/$p.json'),
                  ),
              ]),
              if (_lastEvent != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Text('Last event: $_lastEvent'),
                ),
              _section('Expressions', [
                for (final e in FabioExpression.values)
                  ChoiceChip(
                    label: Text(e.name),
                    selected: e == _expression,
                    onSelected: (_) => setState(() => _expression = e),
                  ),
              ]),
              _section('Gestures', [
                for (final g in FabioGesture.values)
                  ActionChip(label: Text(g.name), onPressed: () => _fabio.play(g)),
              ]),
              _section('Props', [
                for (final p in FabioProp.values)
                  ActionChip(
                    label: Text(p.name),
                    onPressed: () => _fabio.burst(p,
                        mode: p == FabioProp.exclaim ||
                                p == FabioProp.question ||
                                p == FabioProp.mic ||
                                p == FabioProp.zzz
                            ? FabioFxMode.float
                            : FabioFxMode.burst,
                        count: 1 +
                            (p == FabioProp.exclaim || p == FabioProp.question ? 0 : 11)),
                  ),
              ]),
            ],
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: FabioStage(
              controller: _stage,
              onEvent: (e) => setState(() => _lastEvent = e),
            ),
          ),
        ),
      ],
    );
  }
}
