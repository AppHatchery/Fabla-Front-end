import UIKit
import Flutter
import Pendo
import FirebaseCore
import FirebaseMessaging
import UserNotifications
import alarm
import ActivityKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {

  @available(iOS 16.2, *)
  private static var currentTimerActivity: Activity<DiaryTimerActivityAttributes>?

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

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let liveActivityChannel = FlutterMethodChannel(
      name: "diary/live_activity",
      binaryMessenger: engineBridge.applicationRegistrar.messenger())
    liveActivityChannel.setMethodCallHandler { [weak self] call, result in
      self?.handleLiveActivityCall(call, result: result)
    }
  }

  private func handleLiveActivityCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard #available(iOS 16.2, *) else {
      result(FlutterError(code: "UNAVAILABLE", message: "Live Activities require iOS 16.2+", details: nil))
      return
    }

    let args = call.arguments as? [String: Any]

    switch call.method {
    case "start":
      guard let endDateMillis = args?["endDateMillis"] as? Double else {
        result(FlutterError(code: "BAD_ARGS", message: "endDateMillis required", details: nil))
        return
      }
      let endDate = Date(timeIntervalSince1970: endDateMillis / 1000)
      let attributes = DiaryTimerActivityAttributes(title: "Diary Timer")
      let state = DiaryTimerActivityAttributes.ContentState(endDate: endDate, pausedRemaining: nil)
      Task {
        if let existing = AppDelegate.currentTimerActivity {
          await existing.end(nil, dismissalPolicy: .immediate)
        }
        do {
          // staleDate == endDate: the system flips the Live Activity to its
          // "complete" appearance (ActivityViewContext.isStale) exactly when
          // the countdown reaches zero, with no app process required — it
          // stays on screen showing completion even if the app is backgrounded.
          AppDelegate.currentTimerActivity = try Activity.request(
            attributes: attributes,
            content: .init(state: state, staleDate: endDate))
          result(nil)
        } catch {
          result(FlutterError(code: "START_FAILED", message: error.localizedDescription, details: nil))
        }
      }

    case "update":
      let endDateMillis = args?["endDateMillis"] as? Double
      let isPaused = args?["isPaused"] as? Bool ?? false
      let pausedRemainingMillis = args?["pausedRemainingMillis"] as? Double
      let endDate = endDateMillis.map { Date(timeIntervalSince1970: $0 / 1000) }
      let state = DiaryTimerActivityAttributes.ContentState(
        endDate: endDate,
        pausedRemaining: isPaused ? (pausedRemainingMillis.map { $0 / 1000 }) : nil)
      Task {
        // No stale date while paused — nothing is counting down.
        await AppDelegate.currentTimerActivity?.update(.init(state: state, staleDate: isPaused ? nil : endDate))
        result(nil)
      }

    case "end":
      Task {
        await AppDelegate.currentTimerActivity?.end(nil, dismissalPolicy: .immediate)
        AppDelegate.currentTimerActivity = nil
        result(nil)
      }

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    Messaging.messaging().apnsToken = deviceToken
  }

  override func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {}
}
