import UIKit
import Flutter
import Pendo
import FirebaseCore
import FirebaseMessaging
import UserNotifications
import alarm
import workmanager_apple

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

    // WorkManager (UIScene): register BGTaskScheduler launch handlers before
    // launch finishes. Under UIScene the plugin's own application callback runs
    // too late, so scheduled periodic tasks would not be delivered without this.
    WorkmanagerPlugin.registerLaunchHandlers()

    // Makes plugins available inside the background isolate engine. Not required
    // for the current dev.log-only task, but required once the worker calls any
    // plugin (Firebase, shared_preferences, networking, etc.).
    WorkmanagerPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    Messaging.messaging().apnsToken = deviceToken
  }

  override func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {}
}
