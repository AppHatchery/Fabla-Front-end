import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'audio_player_provider.dart';

List<SingleChildWidget> providers = [
  ChangeNotifierProvider(
    create: (_) => AudioPlayerProvider(),
  ),
];
