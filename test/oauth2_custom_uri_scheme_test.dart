import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oauth2_custom_uri_scheme/oauth2_custom_uri_scheme.dart';

void main() {
  const MethodChannel channel = MethodChannel('oauth2_custom_uri_scheme');

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await Oauth2CustomUriScheme.platformVersion, '42');
  });
}
