enum DiaryStatus { idle, ongoing, complete, submitted, missed }

enum RecorderState {
  isStopped,
  isPaused,
  isRecording,
}

enum SubmissionStatus { pending, successful, failed }

/// Drives the phase of the single study-update dialog ([StudyUpdatePopUp]).
enum UpdateState { pending, updating, failed, complete}

enum TimerStatus { idle, running, paused, complete }

TimerStatus status = TimerStatus.idle;

// Derived — no stored booleans needed
bool get inProgress => status == TimerStatus.running || status == TimerStatus.paused;
bool get isRunning => status == TimerStatus.running;
bool get isPaused => status == TimerStatus.paused;
bool get isComplete => status == TimerStatus.complete;
