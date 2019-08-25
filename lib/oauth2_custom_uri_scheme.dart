import 'dart:async';

import 'package:flutter/services.dart';

class Oauth2CustomUriScheme {
  static const MethodChannel _channel =
      const MethodChannel('oauth2_custom_uri_scheme');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
