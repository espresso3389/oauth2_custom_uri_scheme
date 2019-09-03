import 'package:flutter/material.dart';
import 'package:oauth2_custom_uri_scheme/oauth2_custom_uri_scheme.dart';
import 'package:oauth2_custom_uri_scheme/oauth2_token_holder.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simple OAuth Sample',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

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

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Simple OAuth Sample'),
      ),
      body: Center(
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
}
