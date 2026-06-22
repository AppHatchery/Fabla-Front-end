class SubmissionProgress {
  final int submissions;
  final bool activateAnimation;
  final int studyID;

  SubmissionProgress(
      {required this.submissions,
      required this.activateAnimation,
      required this.studyID});

  factory SubmissionProgress.fromJson(int studyID, Map<String, dynamic> json) {
    return SubmissionProgress(
        studyID: studyID,
        submissions: json['submissions'] as int,
        activateAnimation: json['activateAnimation'] as bool);
  }

  Map<String, dynamic> toJson() {
    return {
      'submissions': submissions,
      'activateAnimation': activateAnimation,
    };
  }
}
