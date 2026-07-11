import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // IMPORTANT: Replace "YOUR_IOS_GOOGLE_MAPS_API_KEY" with your actual
    // Google Maps Platform API key from https://console.cloud.google.com/
    // Ensure the "Maps SDK for iOS" is enabled for this key.
    GMSServices.provideAPIKey("YOUR_IOS_GOOGLE_MAPS_API_KEY")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
