import Flutter
import UIKit
import Pendo

class SceneDelegate: FlutterSceneDelegate {
  override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    if let url = URLContexts.first?.url, url.scheme?.range(of: "pendo") != nil {
      PendoManager.shared().initWith(url)
    }
    super.scene(scene, openURLContexts: URLContexts)
  }
}
