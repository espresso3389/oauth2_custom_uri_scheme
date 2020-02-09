package jp.espresso3389.oauth2_custom_uri_scheme

import android.content.Context
import android.content.Intent

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar
import io.flutter.plugin.common.PluginRegistry.NewIntentListener

/** Oauth2CustomUriSchemePlugin */
public class Oauth2CustomUriSchemePlugin: FlutterPlugin, MethodCallHandler, ActivityAware, NewIntentListener {
  private var methodChannel: MethodChannel? = null
  private var eventChannel: EventChannel? = null
  private var activityPluginBinding: ActivityPluginBinding?= null

  private var eventSink: EventChannel.EventSink? = null
  private var customScheme: String? = null

  // This static function is optional and equivalent to onAttachedToEngine. It supports the old
  // pre-Flutter-1.12 Android projects. You are encouraged to continue supporting
  // plugin registration via this function while apps migrate to use the new Android APIs
  // post-flutter-1.12 via https://flutter.dev/go/android-project-migration.
  //
  // It is encouraged to share logic between onAttachedToEngine and registerWith to keep
  // them functionally equivalent. Only one of onAttachedToEngine or registerWith will be called
  // depending on the user's project. onAttachedToEngine or registerWith must both be defined
  // in the same class.
  companion object {
    @JvmStatic
    fun registerWith(registrar: Registrar) {
      println("Oauth2CustomUriSchemePlugin.registerWith")
      Oauth2CustomUriSchemePlugin().onAttachedToEngine(registrar.context(), registrar.messenger())
    }
  }

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    println("Oauth2CustomUriSchemePlugin.onAttachedToEngine")
    onAttachedToEngine(binding.applicationContext, binding.binaryMessenger)
  }

  fun onAttachedToEngine(applicationContext: Context, messenger: BinaryMessenger) {
    println("Oauth2CustomUriSchemePlugin.onAttachedToEngine")
    methodChannel = MethodChannel(messenger, "oauth2_custom_uri_scheme")
    methodChannel!!.setMethodCallHandler(this)
    eventChannel = EventChannel(messenger, "oauth2_custom_uri_scheme/events")
    eventChannel!!.setStreamHandler(object: EventChannel.StreamHandler {
      override fun onListen(obj: Any?, eventSink: EventChannel.EventSink?) {
        this@Oauth2CustomUriSchemePlugin.eventSink = eventSink
      }

      override fun onCancel(obj: Any?) {
        this@Oauth2CustomUriSchemePlugin.eventSink = null
      }
    })
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    println("Oauth2CustomUriSchemePlugin.onDetachedFromEngine")
    methodChannel?.setMethodCallHandler(null)
    methodChannel = null
    eventChannel?.setStreamHandler(null)
    eventChannel = null
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    println("Oauth2CustomUriSchemePlugin.onAttachedToActivity")
    activityPluginBinding = binding
    binding.addOnNewIntentListener(this)
  }

  override fun onDetachedFromActivity() {
    println("Oauth2CustomUriSchemePlugin.onDetachedFromActivity")
    activityPluginBinding?.removeOnNewIntentListener(this)
    activityPluginBinding = null
  }

  override fun onDetachedFromActivityForConfigChanges() {
    println("Oauth2CustomUriSchemePlugin.onDetachedFromActivityForConfigChanges")
    activityPluginBinding?.removeOnNewIntentListener(this)
    activityPluginBinding = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    println("Oauth2CustomUriSchemePlugin.onReattachedToActivityForConfigChanges")
    activityPluginBinding = binding
    binding.addOnNewIntentListener(this)
  }

  override fun onNewIntent(intent: Intent?): Boolean {
    if (intent?.action == Intent.ACTION_VIEW && intent.data?.scheme == customScheme) {
      eventSink?.success(mapOf("type" to "url", "url" to intent?.data?.toString()))
    }
    return true
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    if (call.method == "customScheme") {
      customScheme = call.arguments as String?
      result.success(null)
    } else {
      result.notImplemented()
    }
  }

}
