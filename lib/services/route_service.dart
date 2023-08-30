import 'package:audio_diaries_flutter/main.dart';
import 'package:audio_diaries_flutter/screens/onboarding/domain/repository/setup_repository.dart';
import 'package:audio_diaries_flutter/screens/onboarding/presentation/pages/welcome.dart';
import 'package:flutter/material.dart';

import '../screens/onboarding/presentation/pages/login.dart';

class RouteService {
  Widget getRoute() {
    final SetupRepository setupRepository = SetupRepository();

    final participant = setupRepository.getParticipant();
    if (participant == null) {
      return const LoginPage();
    } else {
      if (participant.name == "") {
        return const WelcomePage();
      }
    }

    return const Hub();
  }
}
