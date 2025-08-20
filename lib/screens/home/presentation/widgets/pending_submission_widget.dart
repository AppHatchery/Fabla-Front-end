import 'dart:async';

import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:audio_diaries_flutter/screens/diary/data/bulk_submission.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/repository/diary_repository.dart';
import 'package:audio_diaries_flutter/theme/components/cards.dart'
    show NoInternetCard, PendingSubmissionCard;
import 'package:flutter/material.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class PendingSubmissionWidget extends StatefulWidget {
  const PendingSubmissionWidget({super.key});

  @override
  State<PendingSubmissionWidget> createState() =>
      _PendingSubmissionWidgetState();
}

class _PendingSubmissionWidgetState extends State<PendingSubmissionWidget> {
  List<DiarySubmission> submissions = [];
  bool connected = true;

  StreamSubscription<InternetStatus>? listener;
  @override
  void initState() {
    super.initState();
    _getDiaries();
    _initConnectivity();
  }

  void _initConnectivity() async {
    listener = InternetConnection().onStatusChange.listen((status) {
      switch (status) {
        case InternetStatus.connected:
          if (mounted) {
            setState(() => connected = true);
          }
          break;
        case InternetStatus.disconnected:
          if (mounted) {
            setState(() => connected = false);
          }
          break;
      }
    });
  }

  @override
  void dispose() {
    listener?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!connected) {
      return Padding(
        padding: EdgeInsets.only(top: 24),
        child: NoInternetCard(),
      );
    }

    return submissions.isEmpty
        ? const SizedBox()
        : Padding(
            padding: EdgeInsets.only(top: 24),
            child: PendingSubmissionCard(
              submissions: submissions,
            ),
          );
  }

  _getDiaries() async {
    final repository = DiaryRepository();
    final diaries = repository.getAllDiaries();
    final filtered =
        diaries.where((element) => element.status == DiaryStatus.complete);

    if (filtered.isEmpty) return;

    final submissions = <DiarySubmission>[];

    for (final diary in filtered) {
      final study = await repository.getStudy(diary.studyID);
      submissions.add(DiarySubmission(diary: diary, study: study!));
    }

    setState(() {
      this.submissions = submissions;
    });
  }
}
