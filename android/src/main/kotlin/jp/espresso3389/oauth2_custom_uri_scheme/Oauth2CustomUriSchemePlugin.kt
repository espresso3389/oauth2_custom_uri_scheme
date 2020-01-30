package jp.espresso3389.oauth2_custom_uri_scheme

import android.content.Intent
import io.flutter.app.FlutterActivity
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar
import android.content.Context.ACTIVITY_SERVICE
import android.app.ActivityManager
import android.os.Build


class Oauth2CustomUriSchemePlugin(registrar: Registrar): MethodCallHandler {

  companion object {
    @JvmStatic
    fun registerWith(registrar: Registrar) {
      val channel = MethodChannel(registrar.messenger(), "oauth2_custom_uri_scheme")
      channel.setMethodCallHandler(Oauth2CustomUriSchemePlugin(registrar))
    }
  }

  init {
    EventChannel(registrar.messenger(), "oauth2_custom_uri_scheme/events").setStreamHandler(object: EventChannel.StreamHandler {
      override fun onListen(obj: Any?, eventSink: EventChannel.EventSink?) {
        this@Oauth2CustomUriSchemePlugin.eventSink = eventSink
      }
      override fun onCancel(obj: Any?) {
        this@Oauth2CustomUriSchemePlugin.eventSink = null
      }
    })

    registrar.addNewIntentListener {
      if (it.action == Intent.ACTION_VIEW && it.data?.scheme == customScheme) {
        eventSink?.success(mapOf("type" to "url", "url" to it?.data?.toString()))
      }
      true
    }
  }

  private val registrar: Registrar = registrar
  private var eventSink: EventChannel.EventSink? = null
  private var customScheme: String? = null

  override fun onMethodCall(call: MethodCall, result: Result) {
    if (call.method == "customScheme") {
      customScheme = call.arguments as String?
      result.success(null)
    } else if (call.method == "closeChrome") {
      val myIntent = Intent(registrar.activity(), registrar.activity().javaClass)
      myIntent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
      myIntent.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
      registrar.view().context.startActivity(myIntent)
      result.success(null)
    } else if (call.method == "activityCount") {
      val activityManager = registrar.context().getSystemService(ACTIVITY_SERVICE) as ActivityManager
      if (Build.VERSION.SDK_INT >= 23) {
        val className = activityManager.appTasks.get(0).taskInfo.topActivity.className
        result.success(if (className.indexOf("CustomTab") >= 0) 2 else 1)
      } else {
        result.success(0)
      }
    } else {
        result.notImplemented()
    }
  }

}
