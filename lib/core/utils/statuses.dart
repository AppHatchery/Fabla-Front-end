enum DiaryStatus { idle, ongoing, complete, submitted, missed }

enum AudioRecordingStatus {
  stopped,
  recording,
  paused,
}

enum RecordingSaveOutcome {
  saved,
  nothingRecorded,
  emptyFile,
  failed,
}

enum SubmissionStatus { pending, successful, failed }

enum TimerStatus { idle, running, paused, complete }

TimerStatus status = TimerStatus.idle;

// Derived — no stored booleans needed
bool get inProgress =>
    status == TimerStatus.running || status == TimerStatus.paused;
bool get isRunning => status == TimerStatus.running;
bool get isPaused => status == TimerStatus.paused;
bool get isComplete => status == TimerStatus.complete;

enum UpdateState {
  pending,
  available,
  updating,
  failed,
  complete,
  connectionError
}

enum UpdateStatus { none, available, pending }

enum AudioStatus {
  loading,
  available,
  fileNotFound,
  noAudioLength,
  canNotPlay
}
