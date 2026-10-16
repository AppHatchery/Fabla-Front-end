import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../main.dart';
import '../../objectbox.g.dart';
import '../../screens/diary/domain/entities/diary_entity.dart';
import '../../screens/diary/domain/entities/prompt_entity.dart';
import '../../screens/diary/domain/entities/protocol_entity.dart';
import '../../screens/home/domain/entities/experiment.dart';
import '../../screens/home/domain/entities/study.dart';
import '../../screens/onboarding/domain/entities/participant.dart';
import '../utils/statuses.dart';

/// A recording file an answer points at, and whether it is on disk.
class RecordingFile {
  final String type;

  /// Relative to the app's documents directory, as stored.
  final String path;

  /// Size on disk, or null when the file is missing.
  final int? bytes;

  const RecordingFile({required this.type, required this.path, this.bytes});

  bool get exists => bytes != null;

  Map<String, dynamic> toJson() => {
        'type': type,
        'file': p.basename(path),
        'bytes': bytes,
      };
}

/// One prompt of a diary. Records whether it has answers, never what they
/// say.
class PromptSummary {
  final int id;
  final int questionNumber;
  final String question;
  final String type;
  final bool required;

  /// Answers saved across all entries.
  final int answerCount;

  /// Whether the diary's current entry has an answer.
  final bool answeredCurrent;

  /// The current entry's recordings.
  final List<RecordingFile> recordings;

  const PromptSummary({
    required this.id,
    required this.questionNumber,
    required this.question,
    required this.type,
    required this.required,
    required this.answerCount,
    required this.answeredCurrent,
    required this.recordings,
  });

  /// Without the question text, to keep exports short.
  Map<String, dynamic> toJson() => {
        'id': id,
        'number': questionNumber,
        'type': type,
        'required': required,
        'answers': answerCount,
        'answered_current_entry': answeredCurrent,
        if (recordings.isNotEmpty)
          'recordings': [for (final r in recordings) r.toJson()],
      };
}

/// A stored diary row: its window, status and progress.
class DiarySummary {
  final int id;
  final int studyID;
  final String name;
  final DateTime start;
  final DateTime end;
  final DateTime due;
  final DiaryStatus status;
  final int entries;
  final int currentEntry;
  final List<int>? activeDays;
  final List<String> submissions;
  final List<String> completions;
  final int notifications;
  final List<PromptSummary> prompts;

  const DiarySummary({
    required this.id,
    required this.studyID,
    required this.name,
    required this.start,
    required this.end,
    required this.due,
    required this.status,
    required this.entries,
    required this.currentEntry,
    required this.activeDays,
    required this.submissions,
    required this.completions,
    required this.notifications,
    required this.prompts,
  });

  /// Completed but not uploaded yet: what the pending submissions card sends.
  bool get isPending => status == DiaryStatus.complete;

  List<RecordingFile> get recordings =>
      [for (final prompt in prompts) ...prompt.recordings];

  int get recordingBytes =>
      recordings.fold(0, (sum, r) => sum + (r.bytes ?? 0));

  int get missingRecordings => recordings.where((r) => !r.exists).length;

  int get answeredCurrent => prompts.where((p) => p.answeredCurrent).length;

  Map<String, dynamic> toJson() => {
        'id': id,
        'study_id': studyID,
        'name': name,
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
        'due': due.toIso8601String(),
        'status': status.name,
        'entry': '$currentEntry/$entries',
        if (activeDays != null) 'active_days': activeDays,
        'submissions': submissions,
        'completions': completions,
        'notifications': notifications,
        'prompts': [for (final prompt in prompts) prompt.toJson()],
      };
}

class StudySummary {
  final int id;
  final String name;
  final String experimentCode;
  final Object? goals;

  const StudySummary({
    required this.id,
    required this.name,
    required this.experimentCode,
    required this.goals,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'experiment_code': experimentCode,
        'goals': goals,
      };
}

/// What is stored on this device, read straight from ObjectBox without the
/// status sweep that `DiaryRepository.getAllDiaries` runs, so looking never
/// changes anything.
///
/// Holds metadata only: answer counts and recording file sizes, never answer
/// text or audio.
///
/// Usage example:
/// ```dart
/// final data = await LocalData.read();
/// final pending = data.diaries.where((d) => d.isPending);
/// ```
class LocalData {
  final String? participantId;
  final Map<String, String>? experiment;
  final Map<String, int>? protocol;
  final List<StudySummary> studies;
  final List<DiarySummary> diaries;

  const LocalData({
    this.participantId,
    this.experiment,
    this.protocol,
    required this.studies,
    required this.diaries,
  });

  /// [documents] is where recording paths resolve; defaults to the app's
  /// documents directory. [where] limits which diaries are read, and
  /// [withPrompts] which of those load their prompts, answers and recording
  /// files (the slow part on studies with hundreds of rows); the rest get
  /// none.
  static Future<LocalData> read({
    Directory? documents,
    bool Function(Diary diary)? where,
    bool Function(Diary diary)? withPrompts,
  }) async {
    final store = objectbox.store;
    final dir = documents ?? await getApplicationDocumentsDirectory();

    final participant = Box<Participant>(store).getAll().firstOrNull;
    final experiment = Box<Experiment>(store).getAll().firstOrNull;
    final protocol = Box<ProtocolEntity>(store).getAll().firstOrNull;

    final diaries =
        Box<Diary>(store).getAll().where(where ?? (_) => true).toList()
          ..sort((a, b) {
            final byStart = a.start.compareTo(b.start);
            return byStart != 0 ? byStart : a.studyID.compareTo(b.studyID);
          });

    return LocalData(
      participantId: participant?.studyCode,
      experiment: experiment == null
          ? null
          : {
              'login': experiment.login,
              'name': experiment.name,
              'version': experiment.version,
            },
      protocol: protocol == null
          ? null
          : {
              'version': protocol.version,
              'daily_goal': protocol.dailyGoal,
              'weekly_goal': protocol.weeklyGoal,
              'blueprints': protocol.diaryBlueprints.length,
            },
      studies: [
        for (final study in Box<Study>(store).getAll())
          StudySummary(
            id: study.studyId,
            name: study.name,
            experimentCode: study.experimentCode,
            goals: _decode(study.goals),
          ),
      ],
      diaries: [
        for (final diary in diaries)
          _diary(diary, dir, withPrompts: withPrompts?.call(diary) ?? true),
      ],
    );
  }

  static DiarySummary _diary(Diary diary, Directory dir,
      {required bool withPrompts}) {
    final prompts = (withPrompts ? diary.prompts.toList() : <Prompt>[])
      ..sort((a, b) => a.questionNumber.compareTo(b.questionNumber));
    return DiarySummary(
      id: diary.id,
      studyID: diary.studyID,
      name: diary.name,
      start: diary.start,
      end: diary.end,
      due: diary.due,
      status: diary.status ?? DiaryStatus.idle,
      entries: diary.entries,
      currentEntry: diary.currentEntry,
      activeDays: diary.activeDays,
      submissions: diary.submissions ?? const [],
      completions: diary.completions ?? const [],
      notifications: (_decode(diary.notifications) as List?)?.length ?? 0,
      prompts: [
        for (final prompt in prompts)
          () {
            final current = prompt.answers.elementAtOrNull(diary.currentEntry);
            return PromptSummary(
              id: prompt.id,
              questionNumber: prompt.questionNumber,
              question: prompt.question,
              type: prompt.responseType?.name ?? 'unknown',
              required: prompt.required,
              answerCount: prompt.answers.length,
              answeredCurrent: current != null,
              recordings: [
                for (final recording in current?.recordings ?? const [])
                  RecordingFile(
                    type: recording.type,
                    path: recording.path,
                    bytes: _size(p.join(dir.path, recording.path)),
                  ),
              ],
            );
          }(),
      ],
    );
  }

  static int? _size(String path) {
    try {
      final file = File(path);
      return file.existsSync() ? file.lengthSync() : null;
    } catch (_) {
      return null;
    }
  }

  static Object? _decode(String raw) {
    try {
      return jsonDecode(raw);
    } catch (_) {
      return raw;
    }
  }

  List<DiarySummary> get pending => diaries.where((d) => d.isPending).toList();

  Map<DiaryStatus, int> get statusCounts => {
        for (final status in DiaryStatus.values)
          status: diaries.where((d) => d.status == status).length,
      };

  String studyName(int studyID) =>
      studies.where((s) => s.id == studyID).firstOrNull?.name ??
      'Study $studyID';

  Map<String, dynamic> toJson() => {
        'participant_id': participantId,
        'experiment': experiment,
        'protocol': protocol,
        'studies': [for (final study in studies) study.toJson()],
        'status_counts': {
          for (final entry in statusCounts.entries) entry.key.name: entry.value,
        },
        'diaries': [for (final diary in diaries) diary.toJson()],
      };
}
