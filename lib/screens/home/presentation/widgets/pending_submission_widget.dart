import 'dart:async';

import 'package:audio_diaries_flutter/screens/diary/data/bulk_submission.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/repository/diary_repository.dart';
import 'package:audio_diaries_flutter/services/developer_mode_service.dart';
import 'package:audio_diaries_flutter/services/pendo_service.dart';
import 'package:audio_diaries_flutter/services/preference_service.dart';
import 'package:audio_diaries_flutter/theme/components/cards.dart'
    show NoInternetCard, PendingSubmissionCard;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class PendingSubmissionWidget extends StatefulWidget {
  const PendingSubmissionWidget({super.key});

  @override
  State<PendingSubmissionWidget> createState() =>
      _PendingSubmissionWidgetState();
}

class _PendingSubmissionWidgetState extends State<PendingSubmissionWidget> {
  final _pref = PreferenceService();
  final _developerMode = DeveloperModeService();
  List<DiarySubmission> submissions = [];
  bool connected = true;
  bool hadNetworkError = false;

  StreamSubscription<InternetStatus>? listener;
  @override
  void initState() {
    super.initState();
    _getDiaries();
    _initConnectivity();
    _developerMode.enabled.addListener(_initConnectivity);
    _developerMode.skipConnectivityCheck.addListener(_initConnectivity);
  }

  void _initConnectivity() async {
    if(kDebugMode) return; // always connected in debug mode
    hadNetworkError =
        await _pref.getBoolPreference(key: 'network_error') ?? false;

    if (listener != null) {
      listener?.cancel();
      listener = null;
    }

    // Developer mode can skip the check: always show as connected.
    if (_developerMode.shouldSkipConnectivityCheck) {
      if (mounted) setState(() => connected = true);
      return;
    }

    final currentStatus = await InternetConnection().internetStatus;
    if (_developerMode.shouldSkipConnectivityCheck) return;

    if (mounted) {
      setState(() => connected = currentStatus == InternetStatus.connected);
    }

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
      _pendoTrack();
    });
  }

  @override
  void didUpdateWidget(covariant PendingSubmissionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _initConnectivity();
  }

  @override
  void dispose() {
    _developerMode.enabled.removeListener(_initConnectivity);
    _developerMode.skipConnectivityCheck.removeListener(_initConnectivity);
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

    return !hadNetworkError
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
    final diaries = await repository.getAllPending();

    if (diaries.isEmpty) return;

    final submissions = <DiarySubmission>[];

    for (final diary in diaries) {
      final study = await repository.getStudy(diary.studyID);
      submissions.add(DiarySubmission(diary: diary, study: study!));
    }

    setState(() {
      this.submissions = submissions;
    });
  }

  _pendoTrack() async {
    await PendoService.track("Internet Connectivity", {
      "status": connected ? "connected" : "disconnected",
      "time": DateTime.now().toIso8601String(),
    });
  }
}
