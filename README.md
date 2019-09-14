# [oauth2_custom_uri_scheme](https://pub.dev/packages/oauth2_custom_uri_scheme/)

An implementation of OAuth 2.0 authorization code grant with redirection to application specific custom URI scheme.

To make the implementation safer (but not perfect), it implements the following features:

- [Custom Chrome Tabs](https://developer.chrome.com/multidevice/android/customtabs) (Android)
  - Automatic Chrome Tab close feature on authorization finish
  - Chrome Tab cancellation detection (API Level >= 23)
- [ASWebAuthenticationSession](https://developer.apple.com/documentation/authenticationservices/aswebauthenticationsession) (iOS 12)
- [SFAuthenticationSession](https://developer.apple.com/documentation/safariservices/sfauthenticationsession) (iOS 11)
- [Proof Key for Code Exchange (PKCE) by OAuth Public Clients](https://tools.ietf.org/html/rfc7636)
  - If PKCE is supported by OAuth service provider, it can prevent access token hijacking

So the implementation fully works on Android with API level >= 23 and iOS >= 11.0.

## Installation

```yaml
dependencies:
  oauth2_custom_uri_scheme: ^0.3.5
```

## Getting Started

```dart
import 'package:oauth2_custom_uri_scheme/oauth2_custom_uri_scheme.dart';
import 'package:oauth2_custom_uri_scheme/oauth2_token_holder.dart';

...

//
// OAuth2Config can be app global to keep the OAuth configuration
//
final oauth2Config = OAuth2Config(
  uniqueId: 'example.com#1', // NOTE: ID to identify the credential for box session
  authorizationEndpoint: Uri.parse('https://example.com/authorize'),
  tokenEndpoint: Uri.parse('https://example.com/token'),
  // revocationEndpoint is optional
  revocationEndpoint: Uri.parse('https://example.com/revoke'),
  // NOTE: For Android, we also have corresponding intent-filter entry on example/android/app/src/main/AndroidManifest.xml
  redirectUri: Uri.parse('com.example.redirect43763246328://callback'),
  clientId: 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
  clientSecret: 'yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy',
  useBasicAuth: false);

...

Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text('Simple OAuth Sample'),
    ),
    body: Center(
      // OAuth2TokenHolder is the easiest way to create [authorize] button.
      child: OAuth2TokenHolder(
        config: oauth2Config,
        builder: (context, accessToken, state, authorize, deauthorize, child) => ListTile(title: RaisedButton(
          onPressed:() => accessToken == null ? authorize() : deauthorize(),
          child: state == OAuth2TokenAvailability.Authorizing
          ? const CircularProgressIndicator()
          : Text(accessToken == null ? 'Authorize' : 'Deauthorize'))
        )
      )
    )
  );
}

// After [Authorize] on the UI, we can get the access token from cache.
AccessToken token = await oauth2Config.getAccessTokenFromCache();

// Or, of course, you can authorize the app
// If reset=false, it may use the cache and the method returns immediately;
// otherwise reset=true, it always tries to authorize the app.
AccessToken token = await oauth2Config.authorize(reset: true);

// OK, we can execute GET query
final foobarResult = await token.getJsonFromUri('https://example.com/api/2.0/foobar');
```

## Lower level API

To use the plugin with your OAuth service provider, call `AccessToken.authorize` with your OAuth service's endpoints and client configuration:

```dart
final AccessToken token = await AccessToken.authorize(
    authorizationEndpoint: Uri.parse('https://example.com/authorize'),
    tokenEndpoint: Uri.parse('https://example.com/token'),
    // NOTE: For Android, we also have corresponding intent-filter entry on example/android/app/src/main/AndroidManifest.xml
    redirectUri: Uri.parse('com.example.redirect43763246328://callback'),
    clientId: 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
    clientSecret: 'yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy',
    useBasicAuth: false, // certain services such as Box does not support Basic Auth
    idForCache: 'example.com#1' // used when caching access token
);
if (token == null) {
    // error handling
}

// OK, we can execute GET query
final foobarResult = await token.getJsonFromUri('https://example.com/api/2.0/foobar');

// POST query
final request = await token.createRequest('POST', 'https://example.com/api/2.0/zzzzz');
request.body = '....';
final response = await request.send();
```

## Additional settings on Android

For Android, we should update several configurations:

We should add `AndroidManifest.xml` to include additional `<intent-filter>` under `<activity>`.

```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <!-- Should match to the one on example/lib/main.dart -->
    <data android:scheme="com.example.redirect43763246328" android:host="callback" />
</intent-filter>
```

In `android/app/build.gradle` set `minSdkVersion` to >= 18.

```gradle
android {
    ...
    defaultConfig {
        ...
        minSdkVersion 18
        ...
    }
}
```

## API reference

[API reference](https://pub.dev/documentation/oauth2_custom_uri_scheme/latest/oauth2_custom_uri_scheme/oauth2_custom_uri_scheme-library.html) on [pub.dev](https://pub.dev).

## <a name="security"></a>Security considerations

On every platform, we can define a custom URI scheme to launch our app on URI redirects.

Although the URI may be something like `myapp://localhost`, the URI scheme here, `myapp` is not suitable for accepting authorization code redirect. If any other apps may use the same URI scheme, the authorization code may be intercepted by them without launching our app.

Basically, it's almost impossible to hide our custom URI scheme from others, apparently, we should choose one carefully not to conflict with other apps.

At least, we should use app scheme like `com.example.mwl5oodcb9`, which contains some random characters (but they should be lowercase anyway).

To reduce the risk of others intercepting authorization code, the plugin implements [RFC 7636: Proof Key for Code Exchange (PKCE) by OAuth Public Clients](https://tools.ietf.org/html/rfc7636). But not every OAuth service implements it.
