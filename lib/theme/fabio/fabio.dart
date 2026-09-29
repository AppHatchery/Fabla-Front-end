/// Fabio, the Fabla mascot, animated procedurally.
///
/// * [Fabio] — a standalone, always-alive widget (tap him!).
/// * [FabioStage] / [showFabioScript] — choreographies where Fabio flies
///   around the screen, spawns props and talks, authored in Fabio Studio
///   and stored as JSON in `assets/fabio/scripts/`.
library;

export 'fabio_custom_prop.dart' show FabioCustomProp, FabioVectorPath, parseSvgPath, parseSvgColor;
export 'fabio_expression.dart';
export 'fabio_fx.dart' show FabioFx, FabioFxMode, FabioPropPhysics;
export 'fabio_rig.dart' show FabioPose, FabioRig;
export 'fabio_script.dart';
export 'fabio_sim.dart';
export 'fabio_stage.dart';
export 'fabio_widget.dart';
