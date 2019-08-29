# oauth2_custom_uri_scheme_example

Demonstrates how to use the oauth2_custom_uri_scheme plugin.

## Getting Started

You should update `example/lib/main.dart` and `example/android/app/src/main/AndroidManifest.xml` (for Android) to use your OAuth server and client configurations:

```dart
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
```

```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <!-- Should match to the one on example/lib/main.dart -->
    <data android:scheme="com.example.redirect43763246328" android:host="callback" />
</intent-filter>
```

For choosing good URL scheme, see [Security considerations](../README.md#security).
