import 'package:audio_diaries_flutter/screens/onboarding/domain/repository/login_repository.dart';
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
        emit(const LoginSuccess());
      } else {
        emit(const LoginError("Oops! We do not have this ID in the participant list. Please check your email and try again."));
      }
    } catch (e) {
      debugPrint(e.toString());
      emit(const LoginError("Something went wrong"));
    }
  }

}
