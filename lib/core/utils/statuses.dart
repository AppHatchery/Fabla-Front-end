enum DiaryStatus { idle, ongoing, complete, submitted, missed }

/// Resolves the local status of an overdue diary without falsely marking a
/// queued upload as submitted. A complete diary must remain pending until
/// the upload code receives success from both S3 and Dynamo.
DiaryStatus? resolveOverdueDiaryStatus(
  DiaryStatus? currentStatus,
  int currentEntry,
) {
  if (currentStatus == DiaryStatus.complete ||
      currentStatus == DiaryStatus.submitted) {
    return currentStatus;
  }
  return currentEntry == 0 ? DiaryStatus.missed : DiaryStatus.submitted;
}

/// Detects the state produced by the old overdue cleanup bug. A successful
/// upload increments [currentEntry], so an extra completion beyond that index
/// means the latest completed entry still needs to be uploaded.
bool hasUnsubmittedCompletion(
  DiaryStatus? currentStatus,
  int currentEntry,
  int completionCount,
) =>
    currentStatus == DiaryStatus.submitted && completionCount > currentEntry;

enum RecorderState {
  isStopped,
  isPaused,
  isRecording,
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
