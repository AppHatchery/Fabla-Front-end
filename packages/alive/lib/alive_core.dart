/// Alive for a screen that plays scenes: the controller, the stage, where scenes come from, events and errors, and
/// the extension points (plugin painters, fonts). The whole package (kits, tools) is `package:alive/alive.dart`.
library;

export 'src/loader/library.dart' show AliveLibrary, AliveCache, AliveSceneHandle;
export 'src/render/art_renderer.dart' show AliveFonts;
export 'src/runtime/events.dart';
export 'src/runtime/extensions.dart' show AliveExtensions, AlivePlugin, AliveNodePainter, AliveFrame;
export 'src/runtime/variants.dart' show AliveStore, AliveMemoryStore, AliveRunContext;
export 'src/schema/art_def.dart' show PluginNode;
export 'src/schema/errors.dart';
export 'src/schema/track.dart' show LayerProp;
export 'src/widget/controller.dart';
export 'src/widget/placement.dart';
export 'src/widget/stage.dart';
