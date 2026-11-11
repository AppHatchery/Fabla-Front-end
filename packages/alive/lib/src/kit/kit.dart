// The kit system's public surface: art packs (kit.json and parts), looks, adjustments.
import 'kit_def.dart';

export 'figure.dart' show KitData, FigureRig, FigureDress, AliveDress;
export 'kit_def.dart' show KitDef, KitSlot, KitPart, KitBone, KitRange, KitPhysics, KitToken, KitGrip;
export 'look.dart' show AliveLook, AlivePartAdjust, WornPart, ResolvedLook, resolveLook, shiftColour;

/// An art pack (the kit.json of `kits/<id>`).
typedef AliveKit = KitDef;
