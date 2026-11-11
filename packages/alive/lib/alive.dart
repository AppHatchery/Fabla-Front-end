/// The Alive engine for Fabla: designed Fabio moments in Flutter.
///
/// A screen holds an [AliveController] (load a scene by id, drive it with app state, mic level, taps and events) and
/// shows it with an [AliveStage]. Scenes are alive/1 files made by the alive CLI from Figma Motion or the board pages
/// (see docs/integration.md and docs/authoring.md).
///
/// Everything: the three parts below, each also importable on its own.
/// - `package:alive/alive_core.dart`: playing scenes on a screen (controller, stage, library, events, extensions).
/// - `package:alive/alive_kit.dart`: kit figures dressed at run time (looks, parts, tints).
/// - `package:alive/alive_tools.dart`: the parsed files, the player and the compiled art, for tools and tests.
library;

export 'alive_core.dart';
export 'alive_kit.dart';
export 'alive_tools.dart';
