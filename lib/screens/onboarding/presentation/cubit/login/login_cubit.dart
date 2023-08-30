import 'package:audio_diaries_flutter/screens/onboarding/domain/repository/login_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

part 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  LoginCubit() : super(const LoginInitial());
  final LoginRepository repository = LoginRepository();

  void login(String code) async {
    emit(const LoginLoading());
    try {
      final result = await repository.verify(code);
      if (result) {
        repository.addParticipant(code);
        emit(const LoginSuccess());
      } else {
        emit(const LoginError("Invalid code"));
      }
    } catch (e) {
      debugPrint(e.toString());
      emit(const LoginError("Something went wrong"));
    }
  }
}
