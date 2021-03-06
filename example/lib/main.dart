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
  MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

final oauth2Config = OAuth2Config(
    uniqueId: 'azuread-common', // NOTE: ID to identify the credential save
    authorizationEndpoint: Uri.parse('https://login.microsoftonline.com/common/oauth2/v2.0/authorize'),
    tokenEndpoint: Uri.parse('https://login.microsoftonline.com/common/oauth2/v2.0/token'),
    // revocationEndpoint is optional
    revocationEndpoint: Uri.parse('https://example.com/revoke'),
    // NOTE: For Android, we also have corresponding intent-filter entry on example/android/app/src/main/AndroidManifest.xml
    redirectUri: Uri.parse('com.example.redirect43763246328://callback'),
    clientId: 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
    clientSecret: 'yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy',
    scope: 'user.read',
    useBasicAuth: false);

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Simple Azure AD OAuth2.0 Example'),
        ),
        body: Center(
            child: OAuth2TokenHolder(
                config: oauth2Config,
                builder: (context, accessToken, state, authorize, deauthorize, child) => ListTile(
                    title: ElevatedButton(
                        onPressed: () => accessToken == null ? authorize() : deauthorizeConfirm(deauthorize),
                        child: state == OAuth2TokenAvailability.Authorizing
                            ? const CircularProgressIndicator()
                            : Text(accessToken == null ? 'Authorize' : 'Deauthorize'))))));
  }

  /// NOTE: it's your app's responsibility to interact with the user; the deauthorize function does not interact with him/her.
  Future<bool> deauthorizeConfirm(void deauthorize()) async {
    final ret = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: Text('Deauthorize App'),
                content: Text('Do you really want to deauthorize the app?'),
                actions: <Widget>[
                  TextButton(child: Text("Cancel"), onPressed: () => Navigator.of(context).pop(false)),
                  TextButton(child: Text("Deauthorize"), onPressed: () => Navigator.of(context).pop(true))
                ]));
    if (ret == true) {
      deauthorize();
    }
    return ret == true;
  }
}
