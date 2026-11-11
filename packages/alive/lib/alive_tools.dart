/// Alive for tools, tests and previews: the parsed files (scenes, art, fragments, path commands), a scene assembled
/// and prepared, the player that evaluates it without widgets, and the compiled art that draws it.
library;

export 'src/render/art_renderer.dart' show CompiledArt;
export 'src/runtime/player.dart' show AlivePlayer, aliveStep;
export 'src/runtime/scene_data.dart' show AliveSceneData;
export 'src/runtime/variants.dart' show VariantPicker;
export 'src/schema/art_def.dart' show ArtDef, Geometry;
export 'src/schema/curves.dart' show Ease;
export 'src/schema/path_data.dart' show PathCommands, PathOp;
export 'src/schema/scene_def.dart' show SceneDef, ClipDef, FigureDef, aliveSchema, aliveVersion, compareVersions;
