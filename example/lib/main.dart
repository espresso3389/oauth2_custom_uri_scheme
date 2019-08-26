import 'package:flutter/material.dart';
import 'package:oauth2_custom_uri_scheme/oauth2_custom_uri_scheme.dart';

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

class _MyHomePageState extends State<MyHomePage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Simple OAuth Sample'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FlatButton(
              child: Text('Authorize'),
              onPressed: () => AccessToken.authorize(
                authorizationEndpoint: Uri.parse('https://example.com/authorize'),
                tokenEndpoint: Uri.parse('https://example.com/token'),
                // NOTE: For Android, we also have corresponding intent-filter entry on example/android/app/src/main/AndroidManifest.xml
                redirectUri: Uri.parse('com.example.redirect43763246328://callback'),
                clientId: 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
                clientSecret: 'yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy',
                useBasicAuth: false,
                ),
            )
          ],
        ),
      )
    );
  }
}
