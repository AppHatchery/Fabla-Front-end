// Fabla Alive: every hook point the app calls, in one place. Each starts with the feature switch, so with the moments
// off (or not compiled in) the app runs exactly its own code.
import 'package:flutter/widgets.dart';

import 'alive_config.dart';
import 'app_update/app_update_fabio.dart';

export 'alive_config.dart';
export 'app_update/app_update_fabio.dart' show AppUpdateFabio, AppUpdateFabioController;

class Alive {
  Alive._();

  static bool get on => AliveConfig.on;

  // ---------------------------------------------------------------------------------------------------------------
  // The app update dialog (theme/dialogs/pop_ups.dart MyUpgradeAlertState).

  /// The update dialog's Fabio: Boost V1, the rocket (walk in, jetpack, hover; Update Now rockets him out; Maybe later
  /// and the "You can still update Fabla" screen play his goodbye: he powers down, lands and waves).
  static const String appUpdateScene = 'au-boost-v1';

  /// A Fabio band for the dialog's top; null when off (the dialog keeps its art). [initialState] starts him in a
  /// state other than "available" (the walk in), for example "later".
  static Widget? appUpdateArt({
    String scene = appUpdateScene,
    AppUpdateFabioController? controller,
    WidgetBuilder? fallback,
    double scale = 1,
    String? initialState,
  }) =>
      on
          ? AppUpdateFabio(
              scene: scene,
              controller: controller,
              scale: scale,
              fallback: fallback,
              initialState: initialState,
              blend: initialState == null, // opening on a state: start it on its first frame, no glide from the walk in
            )
          : null;

  /// Loads the dialog's scene before it shows; nothing when off.
  static void preloadAppUpdate() {
    if (on) AppUpdateFabio.preload(appUpdateScene);
  }
}
