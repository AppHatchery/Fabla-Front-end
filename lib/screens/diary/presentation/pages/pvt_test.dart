import 'dart:async';
import 'package:audio_diaries_flutter/screens/diary/data/diary.dart';
import 'package:audio_diaries_flutter/screens/diary/presentation/cubit/pvt_test/pvt_cubit.dart';
import 'package:audio_diaries_flutter/screens/diary/presentation/pages/diarysummary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PvtTestPage extends StatefulWidget {
  final DiaryModel diary;

  const PvtTestPage({super.key, required this.diary});

  @override
  State<PvtTestPage> createState() => _PvtTestPageState();
}

class _PvtTestPageState extends State<PvtTestPage> {
  Timer? _timer;
  int _elapsedMs = 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _elapsedMs = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      setState(() {
        _elapsedMs += 16;
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
    _elapsedMs = 0;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PvtCubit(),
      child: Scaffold(
        body: SafeArea(
          child: Builder(
            builder: (builderContext) =>
                BlocBuilder<PvtCubit, PvtState>(builder: (context, state) {
              final cubit = context.read<PvtCubit>();
              final isTestFinished = state.isFinished;

              // Timer logic: start/stop based on stimulus visibility
              if (state.isStimulusVisible && _timer == null) {
                _startTimer();
              } else if (!state.isStimulusVisible && _timer != null) {
                _stopTimer();
              }

              String cardText;
              if (isTestFinished) {
                cardText = "";
              } else if (!state.isTestStarted) {
                cardText = "Get ready...";
              } else if (state.isStimulusVisible) {
                cardText = "${_elapsedMs} ms";
              } else {
                cardText = "Get ready...";
              }

              return Column(
                children: [
                  //progress bar
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: LinearProgressIndicator(
                      value: isTestFinished ? 1.0 : 0.5,
                      backgroundColor: Colors.grey[300],
                      color: Colors.orange,
                    ),
                  ),

                  const SizedBox(height: 16),

                  Expanded(
                    child: Center(
                      child: Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 6,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: isTestFinished
                              ? Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text("✅ Test Complete",
                                        style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 16),
                                    Text(
                                        "Avg RT: ${cubit.getResultSummary().averageReactionTime.toStringAsFixed(2)} ms",
                                        style: const TextStyle(fontSize: 18)),
                                    const SizedBox(height: 8),
                                    Text(
                                        "Lapses: ${cubit.getResultSummary().lapseCount}",
                                        style: const TextStyle(fontSize: 18)),
                                    const SizedBox(height: 8),
                                    Text(
                                        "False Starts: ${cubit.getResultSummary().falseStartCount}",
                                        style: const TextStyle(fontSize: 18)),
                                  ],
                                )
                              : Text(
                                  cardText,
                                  style: const TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ),
                  ),

                  // Tap/Wait Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isTestFinished
                            ? null
                            : (!state.isTestStarted
                                ? () {
                                    cubit.startTest();
                                  }
                                : () {
                                    cubit.recordResponse();
                                  }),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: !state.isTestStarted
                              ? Colors.blue
                              : (state.isStimulusVisible
                                  ? Colors.green
                                  : Colors.grey),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30, vertical: 18),
                        ),
                        child: Text(
                          !state.isTestStarted
                              ? 'START TEST'
                              : (state.isStimulusVisible
                                  ? 'TAP NOW'
                                  : 'WAIT...'),
                          style: const TextStyle(
                              fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back),
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isTestFinished
                                ? () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => DiarySummaryPage(
                                            diary: widget.diary),
                                        settings: const RouteSettings(
                                            name: "/DiarySummaryPage"),
                                      ),
                                    );
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.all(16),
                            ),
                            child: const Text(
                              "Continue",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}
