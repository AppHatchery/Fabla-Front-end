import 'package:audio_diaries_flutter/screens/onboarding/domain/repository/login_repository.dart';
import 'package:audio_diaries_flutter/screens/onboarding/domain/repository/setup_repository.dart';
import 'package:audio_diaries_flutter/services/crashlytics_service.dart'
    show CrashlyticsService;
import 'package:audio_diaries_flutter/services/pendo_service.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
part 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  LoginCubit() : super(const LoginInitial());
  final LoginRepository repository = LoginRepository();

  /// Handles the participant login process and updates the state accordingly.
  ///
  /// This function is responsible for handling the participant login process by
  /// verifying the provided [code]. It emits different states to reflect the
  /// login process and outcome:
  ///   - `LoginLoading`: Indicates that the login process has started.
  ///   - `LoginSuccess`: Indicates successful login after code verification.
  ///   - `LoginError`: Indicates an error during the login process and provides
  ///                   an error message, such as an invalid code or general error.
  ///
  /// Parameters:
  /// - [code]: The participant's login code to be verified.
  ///
  void login(String code) async {
    emit(const LoginLoading());
    try {
      final result = await repository.verify(code);
      if (result) {
        try {
          final setupRepository = SetupRepository();
          final experiment = setupRepository.getExperiment();
          await PendoService.start(code, experiment.login);
        } catch (e, stackTrace) {
          CrashlyticsService().recordError(e, stackTrace,
              reason: "Pendo session handling failed");
          debugPrint('Pendo session handling error: $e');
        }
        emit(const LoginSuccess());
      } else {
        PendoService.track("Participant Login", {
          "participant_id": code,
          "status": "error",
        });
        emit(const LoginError(
            "Oops! We do not have this ID in the participant list. Please check your email and try again."));
      }
    } catch (e, stackTrace) {
      debugPrint(e.toString());
      CrashlyticsService()
          .recordError(e, stackTrace, reason: 'Error in LoginCubit.login');
      emit(const LoginError("Something went wrong"));
    }
  }
}
