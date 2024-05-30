// import 'package:amplify_api/amplify_api.dart';
// import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
// import 'package:amplify_flutter/amplify_flutter.dart';
// import 'package:amplify_storage_s3/amplify_storage_s3.dart';

//TODO: TO BE REMOVED
//import 'package:audio_diaries_flutter/models/ModelProvider.dart';

//import '../amplifyconfiguration.dart';

/// Configures the Amplify framework for authentication and storage.
///
/// This function sets up and configures the Amplify framework to enable
/// authentication using Cognito and storage using Amazon S3. It adds the
/// necessary plugins and configuration based on the provided [amplifyconfig].
///
/// Example usage:
/// ```dart
/// await configureAmplify(); // Configure Amplify for authentication and storage.
/// ```
// Future<void> configureAmplify() async {
//   try {
//     final auth = AmplifyAuthCognito();
//     final storage = AmplifyStorageS3();
//     final api = AmplifyAPI(modelProvider: ModelProvider.instance);
    
//     await Amplify.addPlugins([auth, storage, api,]);
//     await Amplify.configure(amplifyconfig);
//   } on Exception catch (e) {
//     print('An error occurred configuring Amplify: $e');
//   }
// }