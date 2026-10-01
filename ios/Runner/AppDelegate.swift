import UIKit
import Flutter
import Pendo
import FirebaseCore
import FirebaseMessaging
import UserNotifications
import alarm
import flutter_foreground_task
import ActivityKit
import AVFoundation

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
    SwiftFlutterForegroundTaskPlugin.setPluginRegistrantCallback { registry in
                GeneratedPluginRegistrant.register(with: registry)
                }
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

    // Joins the segments of a recording split by an interruption. See
    // AudioRecordingService and AudioSegmentMerger on the Dart side.
    let audioSegmentsChannel = FlutterMethodChannel(
      name: "diary/audio_segments",
      binaryMessenger: engineBridge.applicationRegistrar.messenger())
    audioSegmentsChannel.setMethodCallHandler { call, result in
      guard call.method == "merge" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let args = call.arguments as? [String: Any],
            let segments = args["segments"] as? [String],
            let output = args["output"] as? String else {
        result(FlutterError(code: "BAD_ARGS", message: "segments and output required", details: nil))
        return
      }
      Task {
        let reply = await AudioSegmentMerger.merge(segments, into: output)
        await MainActor.run { result(reply) }
      }
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
      let totalDurationMillis = args?["totalDurationMillis"] as? Double
      let totalDuration = totalDurationMillis.map { $0 / 1000 } ?? endDate.timeIntervalSinceNow
      let attributes = DiaryTimerActivityAttributes(title: "Diary Timer", totalDuration: totalDuration)
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

/// Joins the m4a segments of one recording into a single file.
///
/// flutter_sound records through AVAudioRecorder, which iOS stops when Siri or
/// a call interrupts it, and resuming that recorder erases the file. So the
/// Dart side records each stretch between interruptions into its own file and
/// asks for them to be joined here once the participant stops.
enum AudioSegmentMerger {
  /// Returns [output] on success, or a FlutterError. The segments are never
  /// touched, so a failure loses nothing.
  ///
  /// Passthrough first: it copies the AAC data as it is, so it is fast and
  /// lossless. Re-encoding is the fallback for segments whose formats do not
  /// match, which a route change between them could cause.
  static func merge(_ segments: [String], into output: String) async -> Any {
    let composition = AVMutableComposition()
    guard let track = composition.addMutableTrack(
      withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else {
      return FlutterError(code: "NO_TRACK", message: "Could not create an audio track", details: nil)
    }

    do {
      var cursor = CMTime.zero
      for path in segments {
        let asset = AVURLAsset(url: URL(fileURLWithPath: path))
        // A segment with no audio in it adds nothing, rather than failing the
        // whole recording.
        guard let source = try await asset.loadTracks(withMediaType: .audio).first else { continue }
        let duration = try await asset.load(.duration)
        try track.insertTimeRange(
          CMTimeRange(start: .zero, duration: duration), of: source, at: cursor)
        cursor = CMTimeAdd(cursor, duration)
      }
      if cursor == .zero {
        return FlutterError(code: "EMPTY", message: "No segment held any audio", details: nil)
      }
    } catch {
      return FlutterError(code: "COMPOSE_FAILED", message: error.localizedDescription, details: nil)
    }

    let outputURL = URL(fileURLWithPath: output)
    var lastError: String?

    for preset in [AVAssetExportPresetPassthrough, AVAssetExportPresetAppleM4A] {
      try? FileManager.default.removeItem(at: outputURL)
      guard let export = AVAssetExportSession(asset: composition, presetName: preset),
            export.supportedFileTypes.contains(.m4a) else { continue }
      export.outputURL = outputURL
      export.outputFileType = .m4a
      await export.export()
      if export.status == .completed { return output }
      lastError = export.error?.localizedDescription
    }

    try? FileManager.default.removeItem(at: outputURL)
    return FlutterError(code: "EXPORT_FAILED", message: lastError, details: nil)
  }
}
