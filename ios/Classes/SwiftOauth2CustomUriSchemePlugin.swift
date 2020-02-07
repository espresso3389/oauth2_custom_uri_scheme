import Flutter
import UIKit
import SafariServices
import AuthenticationServices

public class SwiftOauth2CustomUriSchemePlugin: NSObject, FlutterPlugin, ASWebAuthenticationPresentationContextProviding {

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "oauth2_custom_uri_scheme", binaryMessenger: registrar.messenger())
    let instance = SwiftOauth2CustomUriSchemePlugin(registrar)
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  var session: Any? = nil
  let registrar: FlutterPluginRegistrar

  init(_ registrar: FlutterPluginRegistrar) {
    self.registrar = registrar
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if call.method == "authSession" {
      guard let args = call.arguments as! NSDictionary? else {
        result(nil)
        return
      }
      guard let url = args["url"] as! String? else {
        result(nil)
        return
      }
      let urlScheme = args["customScheme"] as? String

      if #available(iOS 12.0, *) {
        var authSession: ASWebAuthenticationSession?
        authSession = ASWebAuthenticationSession(url: URL(string: url)!, callbackURLScheme: urlScheme) { url, error in
          result(url?.absoluteString)
          authSession!.cancel()
          self.session = nil
        }
        session = authSession
        if #available(iOS 13.0, *) {
            authSession?.presentationContextProvider = self
        }
        if !authSession!.start() {
          print("ASWebAuthenticationSession.start failed.")
        }
      } else if #available(iOS 11.0, *) {
        var authSession: SFAuthenticationSession?
        authSession = SFAuthenticationSession(url: URL(string: url)!, callbackURLScheme: urlScheme) { url, error in
          result(url?.absoluteString)
          authSession!.cancel()
          self.session = nil
        }
        session = authSession
        if !authSession!.start() {
          print("SFAuthenticationSession.start failed.")
        }
      } else {
        result(nil)
        return
      }
    }
  }

  @available(iOS 12.0, *)
  public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
    return UIApplication.shared.delegate!.window!!
  }
}
