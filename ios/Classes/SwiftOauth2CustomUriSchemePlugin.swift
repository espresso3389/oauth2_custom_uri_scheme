import Flutter
import UIKit

public class SwiftOauth2CustomUriSchemePlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "oauth2_custom_uri_scheme", binaryMessenger: registrar.messenger())
    let instance = SwiftOauth2CustomUriSchemePlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    result("iOS " + UIDevice.current.systemVersion)
  }
}
