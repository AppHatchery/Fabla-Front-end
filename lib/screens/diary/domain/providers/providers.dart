import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'audio_player_provider.dart';

// A List of providers used in the app. If in the future we want to add another provider it will be added here
List<SingleChildWidget> providers = [
  // Creates and provides the AudioPlayerProvider instance
  ChangeNotifierProvider(
    create: (_) => AudioPlayerProvider(),
  ),
];
