import UIKit
import Flutter
import Pendo
import FirebaseCore
import FirebaseMessaging
import UserNotifications
import alarm

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
    
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
      FirebaseApp.configure()
      
      UNUserNotificationCenter.current().delegate = self

      application.registerForRemoteNotifications()
      if #available(iOS 10.0, *) {
        UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
      }
      SwiftAlarmPlugin.registerBackgroundTasks()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // UIScene lifecycle: plugins are registered once the implicit engine
  // (created by FlutterSceneDelegate) is ready, not in didFinishLaunching.
  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
    
    // APNs token received
    override  func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
           Messaging.messaging().apnsToken = deviceToken
          // let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
          // print("APNs device token: \(tokenString)")
       }
       
       // Handle token errors
    override  func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
         //  print("Failed to register for remote notifications: \(error.localizedDescription)")
       }
        
}

// With the UIScene lifecycle, URLs are delivered to the scene delegate instead of
// application(_:open:options:), so Pendo deep links are handled here.
class SceneDelegate: FlutterSceneDelegate {
  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)
    // Cold launch from a URL.
    handlePendoURLs(connectionOptions.urlContexts)
  }

  override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    super.scene(scene, openURLContexts: URLContexts)
    handlePendoURLs(URLContexts)
  }

  private func handlePendoURLs(_ contexts: Set<UIOpenURLContext>) {
    for context in contexts where context.url.scheme?.range(of: "pendo") != nil {
      PendoManager.shared().initWith(context.url)
    }
  }
}
