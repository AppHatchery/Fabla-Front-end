import 'dart:async';
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/pvt_result.dart';

part 'pvt_state.dart';

class PvtCubit extends Cubit<PvtState> {
  PvtCubit() : super(PvtState());

  DateTime? _stimulusStart;
  final _random = Random();
  Timer? _testTimer; // Timer for the 3-minute duration
  Timer? _stimulusTimer; // Timer for individual stimulus delays
  final Duration _testDuration = const Duration(minutes: 1);

  void startTest() {
    // Reset state for a new test run
    emit(PvtState(isTestStarted: true)); 
    _testTimer?.cancel(); 
    _stimulusTimer?.cancel(); 

    // Start the overall test timer
    _testTimer = Timer(_testDuration, _finishTest);

    // Schedule the first stimulus
    _nextStimulus();
  }

  void _nextStimulus() async {
    _stimulusTimer?.cancel(); // Cancel previous stimulus timer if any
    if (!(_testTimer?.isActive ?? false)) return; // to avoid another test if test is over

    final delay = Duration(seconds: 2 + _random.nextInt(10));
    _stimulusTimer = Timer(delay, () {
      if (!(_testTimer?.isActive ?? false)) return; // Check again before showing
      _stimulusStart = DateTime.now();
      emit(state.copyWith(isStimulusVisible: true));
    });
  }


void recordResponse() {
  if (!state.isStimulusVisible) {
    emit(state.copyWith(falseStartCount: state.falseStartCount + 1));
    return;
  }

  if (_stimulusStart == null) return;
  if (!(_testTimer?.isActive ?? false)) return; // to ignore taps after test ends

  final responseTime = DateTime.now().difference(_stimulusStart!);
  final updatedTimes = [...state.reactionTimes, responseTime];

  emit(state.copyWith(
    isStimulusVisible: false,
    reactionTimes: updatedTimes,
  ));

  // Schedule next stimulus immediately after response
  _nextStimulus();
}

void _finishTest() {
  _stimulusTimer?.cancel(); // Stop any pending stimulus
  _testTimer?.cancel();
  emit(state.copyWith(isFinished: true, isStimulusVisible: false));
}

PvtResult getResultSummary() {
  final lapses = state.reactionTimes.where((t) => t.inMilliseconds > 500).length;
  return PvtResult(
    reactionTimes: state.reactionTimes,
    lapseCount: lapses,
    falseStartCount: state.falseStartCount,
  );
}

@override
Future<void> close() {
  _testTimer?.cancel();
  _stimulusTimer?.cancel();
  return super.close();
}
}
