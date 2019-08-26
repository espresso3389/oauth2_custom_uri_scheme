# oauth2_custom_uri_scheme

An implementation of OAuth 2.0 authorization code grant with redirection to application specific custom URL scheme.

To make the implementation safer (but not perfect), it implements the following features:

- [Custom Chrome Tabs](https://developer.chrome.com/multidevice/android/customtabs) (Android)
- [ASWebAuthenticationSession](https://developer.apple.com/documentation/authenticationservices/aswebauthenticationsession) (iOS 12)
- [SFAuthenticationSession](https://developer.apple.com/documentation/safariservices/sfauthenticationsession) (iOS 11)
- [Proof Key for Code Exchange (PKCE) by OAuth Public Clients](https://tools.ietf.org/html/rfc7636)

## Getting Started

To use the plugin with your OAuth server, call `AccessToken.authorize` with your server's endpoints and client configuration:

```dart
final AccessToken token = await AccessToken.authorize(
    authorizationEndpoint: Uri.parse('https://example.com/authorize'),
    tokenEndpoint: Uri.parse('https://example.com/token'),
    // NOTE: For Android, we also have corresponding intent-filter entry on example/android/app/src/main/AndroidManifest.xml
    redirectUri: Uri.parse('com.example.redirect43763246328://callback'),
    clientId: 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
    clientSecret: 'yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy',
    useBasicAuth: false, // certain services such as Box does not support Basic Auth
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

```dart
class AccessToken {
  final Uri tokenEndpoint;
  final bool useBasicAuth;

  String get accessToken;
  String get tokenType;
  int get expiresIn;
  DateTime get expiry;
  String get refreshToken;
  Map<String, dynamic> get fields;
  DateTime get timeStamp;

  String serialize();
  static AccessToken deserialize(String jsonStr);

  static Future<AccessToken> authorize({
    @required Uri authorizationEndpoint,
    @required Uri tokenEndpoint,
    @required Uri redirectUri,
    @required String clientId,
    @required String clientSecret,
    String login,
    String scope,
    List<String> scopes,
    bool useBasicAuth = true,
    Map<String, String> additionalQueryParams,
    String idForCache,
    String storeId});

  Future<bool> refresh();
  Future<bool> refreshIfNeeded({Duration error});

  Future<bool> saveToken({
    @required String id,
    String storeId,
    bool allowOverwrite = true});

  Future<Request> createRequest(String method, Uri uri);

  Future<ByteStream> getByteStreamFromUri(Uri uri);
  Future<String> getStringFromUri(Uri uri);
  Future<dynamic> getJsonFromUri(Uri uri);
}

class AccessTokenStore {
  static AccessTokenStore fromId(String storeId);

  Future<Map<String, AccessToken>> getSavedTokens();
  Future<AccessToken> getSavedToken({@required String id});
  Future<void> removeSavedTokens({@required Iterable<String> ids});
  Future<void> removeAllSavedTokens();
}
```

## <a name="security"></a>Security considerations

On every platform, we can define a custom URL scheme to launch our app on URL redirects.

Although the URL may be something like `myapp://localhost`, the URL scheme here, `myapp` is not suitable for accepting authorization code redirect. If any other apps may use the same URL scheme, the authorization code may be intercepted by them without launching our app.

Basically, it's almost impossible to hide our custom URL scheme from others, apparently, we should choose one carefully not to conflict with other apps.

At least, we should use app scheme like `com.example.mwl5oodcb9`, which contains some random characters (but they should be lowercase anyway).

To reduce the risk of others intercepting authorization code, the plugin implements [RFC 7636: Proof Key for Code Exchange (PKCE) by OAuth Public Clients](https://tools.ietf.org/html/rfc7636). But not every OAuth service implements it.
