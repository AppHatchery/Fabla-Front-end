import 'package:audio_diaries_flutter/screens/onboarding/domain/repository/login_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
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
        emit(const LoginError("Invalid code"));
      }
    } catch (e) {
      debugPrint(e.toString());
      emit(const LoginError("Something went wrong"));
    }
  }

  final _storage = const FlutterSecureStorage();
  void login_(int code) async {
    emit(const LoginLoading());
    try {
      var response = await http.post(
        Uri.parse(
            'https://3z44ix42wc77473ramwyoqr6ji0fswhn.lambda-url.us-east-1.on.aws/api/getdata'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'StudyCode': code.toString(),
        },
      );

      if (response.statusCode == 200) {
        String jsonString = response.body;
        Map<String, dynamic> data = jsonDecode(jsonString);
        bool exists_ = data['exists'];
        if (exists_ == true) {
          String authorization = data['message']['Authorization'];
          String apiKey = data['message']['x-api-key'];
          String dynamoUrl = data['message']['dynamo_url'];
          String presignedUrl = data['message']['presigned_url'];
          save(CredentialsModel(
              authorization: authorization,
              xapikey: apiKey,
              dynamo_url: dynamoUrl,
              presigned_url: presignedUrl));

          print("Adding participant... $code");
          repository.addParticipant(code.toString());
          emit(const LoginSuccess());
        } else {
          emit(const LoginError("Invalid code"));
        }
      } else {
        emit(const LoginError("Invalid code"));
      }
    } catch (e) {
      debugPrint(e.toString());
      emit(const LoginError("Something went wrong"));
    }
  }

  Future<CredentialsModel?> read() async {
    final credentialsModel = await _storage.read(key: 'credentials');
    if (credentialsModel?.isNotEmpty ?? false) {
      return CredentialsModel.fromJson(json.decode(credentialsModel!));
    }
    return null;
  }

  Future<void> save(CredentialsModel credentialsModel) async {
    await _storage.write(
        key: 'credentials', value: json.encode(credentialsModel.toJson()));
  }
}

class CredentialsModel {
  String? authorization;
  String? xapikey;
  // ignore: non_constant_identifier_names
  String? dynamo_url;
  // ignore: non_constant_identifier_names
  String? presigned_url;

  CredentialsModel(
      // ignore: non_constant_identifier_names
      {this.authorization,
      this.xapikey,
      this.dynamo_url,
      this.presigned_url});

  CredentialsModel.fromJson(Map<String, dynamic> json) {
    authorization = json['authorization'];
    xapikey = json['x-api-key'];
    dynamo_url = json['dynamo_url'];
    presigned_url = json['presigned_url'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['authorization'] = authorization;
    data['x-api-key'] = xapikey;
    data['dynamo_url'] = dynamo_url;
    data['presigned_url'] = presigned_url;
    return data;
  }
}
