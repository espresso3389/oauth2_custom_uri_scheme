import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart' as customTab;

/// Access token.
class AccessToken {
  static final methodChannel = MethodChannel('oauth2_custom_uri_scheme');
  static final eventChannel = EventChannel('oauth2_custom_uri_scheme/events');
  static final Stream<dynamic> eventStream = eventChannel.receiveBroadcastStream();

  /// Token endpoint URL.
  final Uri tokenEndpoint;
  /// Wether the server can accept `Authorizaion: Basic` on HTTP header or not. Certain services does not support it.
  final bool useBasicAuth;
  final String _clientId;
  final String _clientSecret;
  DateTime _timeStamp;
  Map<String, dynamic> _fields;

  /// `access_token`; the access token.
  String get accessToken => _fields['access_token'] as String;
  /// `token_type`; token type. Normally, it is `Bearer`.
  String get tokenType => _fields['token_type'] as String;
  /// `expires_in`; the token's life time in seconds.
  int get expiresIn => _fields['expires_in'] as int;
  /// The expiry calculated based on [timeStamp] and [expiresIn].
  DateTime get expiry => _timeStamp.add(Duration(seconds: expiresIn));
  /// `refresh_token`; the refresh token.
  String get refreshToken => _fields['refresh_token'] as String;
  /// Raw fields returned by the server (Unmodifiable).
  Map<String, dynamic> get fields => _fields;
  /// When the access token is obtained.
  DateTime get timeStamp => _timeStamp;

  bool _validateAndSetFields(Map<String, dynamic> fields) {
    if (fields['access_token'] is String && fields['token_type'] is String && fields['expires_in'] is int && fields['refresh_token'] is String) {
      _fields = Map<String, dynamic>.unmodifiable(fields);
      return true;
    }
    return false;
  }

  AccessToken._({@required this.tokenEndpoint, @required this.useBasicAuth, @required String clientId, @required String clientSecret, DateTime timeStamp, Map<String, dynamic> fields}):
    this._clientId = clientId,
    this._clientSecret = clientSecret,
    this._timeStamp = timeStamp ?? DateTime.now(),
    this._fields = Map<String, dynamic>.unmodifiable(fields ?? {});

  String serialize() => JsonEncoder().convert({
      'tokenEndpoint': tokenEndpoint.toString(),
      'useBasicAuth': useBasicAuth,
      'clientId': _clientId,
      'clientSecret': _clientSecret,
      'timeStamp': _timeStamp.millisecondsSinceEpoch,
      'fields': _fields
    });

  /// Deserialize [AccessToken] from [jsonStr]. If [jsonStr] is null, the function returns null.
  static AccessToken deserialize(String jsonStr) {
    if (jsonStr == null) {
      return null;
    }
    final json = JsonDecoder().convert(jsonStr);
    return AccessToken._(
      tokenEndpoint: Uri.parse(json['tokenEndpoint']),
      useBasicAuth: json['useBasicAuth'],
      clientId: json['clientId'],
      clientSecret: json['clientSecret'],
      timeStamp: DateTime.fromMillisecondsSinceEpoch(json['timeStamp'] as int),
      fields: json['fields']
    );
  }

  /// Authorize the user and return an [AccessToken] or null.
  /// If [idForCache] is specified, the token may be restored from cache and if a token is newly obtained, the token will be saved on the cache. See [AcecssTokenStore] for more.
  static Future<AccessToken> authorize({@required Uri authorizationEndpoint, @required Uri tokenEndpoint, @required Uri redirectUri, @required String clientId, @required String clientSecret, String login, String scope, List<String> scopes, bool useBasicAuth = true, Map<String, String> additionalQueryParams, String idForCache, String storeId}) async {

    if (idForCache != null) {
      final cachedToken = await AccessTokenStore.fromId(storeId).getSavedToken(id: idForCache);
      if (cachedToken != null) {
        return cachedToken;
      }
    }

    final state = _cryptRandom(32);
    final codeVerifier = _cryptRandom(80); // RFC 7636: PKCE extension; at least 43 chars, up to 128 chars.

    final queryParams = Map<String, String>();
    if (additionalQueryParams != null) {
      queryParams.addAll(additionalQueryParams);
    }
    queryParams.addAll({
      'response_type': 'code',
      'client_id': clientId,
      'redirect_uri': redirectUri.toString(),
      'state': state,
      'code_challenge_method': 'S256',
      'code_challenge': _sha256str(codeVerifier)
    });
    if (login != null) {
      queryParams['login'] = login;
    }
    if (scope == null && scopes != null) {
      scope = (<String>[]..addAll(scopes)..sort((a, b) => a.compareTo(b))).reduce((a, b) => '$a $b');
    }
    if (scope != null) {
      queryParams['scope'] = scope;
    }

    final authUrl = authorizationEndpoint.replace(queryParameters: queryParams);

    String query;
    if (Platform.isAndroid) {
      await methodChannel.invokeMethod('customScheme', redirectUri.scheme);
      customTab.launch(authUrl.toString(), option: customTab.CustomTabsOption());
      final completer = Completer<String>();
      final sub = eventStream.listen((data) async {
        if (data['type'] == 'url') {
          completer.complete(data['url']?.toString());
        }
      });
      final redUrl = Uri.parse(await completer.future);
      query = redUrl.query;
      sub.cancel();
      // Closing Chrome custom tab that is shown over our Flutter's Activity
      await methodChannel.invokeMethod('closeChrome');
    } else {
      final redUrl = Uri.parse(await methodChannel.invokeMethod<String>(
        'authSession', {'url': authUrl.toString(), 'customScheme': redirectUri.scheme}));
      query = redUrl.query;
    }

    final params = Uri.splitQueryString(query);
    if (params['state'] != state) {
      // state is different; possible authorization code injection attack.
      throw Exception('state not match; possible authorization code injection.');
    }

    final token = AccessToken._(useBasicAuth: useBasicAuth, tokenEndpoint: tokenEndpoint, clientId: clientId, clientSecret: clientSecret);
    if (!await token._updateToken({'grant_type': 'authorization_code', 'code': params['code'], 'code_verifier': codeVerifier})) {
      return null;
    }

    if (idForCache != null) {
      token.saveToken(id: idForCache, storeId: storeId);
    }

    return token;
  }

  /// Refresh access token immediately.
  Future<bool> refresh() => _updateToken({ 'grant_type': 'refresh_token', 'refresh_token': refreshToken });

  /// Refresh access token if needed.
  /// Because [expiry] is calculated on client side after receiving the access token, the access token may be invalidated a little before
  /// it; if [error] is set, the access token is refreshed before the calculated [expiry].
  Future<bool> refreshIfNeeded({Duration error}) async {
    error ??= Duration(seconds: 30);
    if (expiry.subtract(error).compareTo(DateTime.now()) < 0)
      return await refresh();
    return false;
  }

  Future<bool> _updateToken(Map<String, String> query) async {
    final tokenReq = Request('POST', tokenEndpoint);
    if (useBasicAuth) {
      tokenReq.headers['Authorization'] = 'Basic ' + base64.encode('$_clientId:$_clientSecret'.codeUnits);
    } else {
      query['client_id'] = _clientId;
      query['client_secret'] = _clientSecret;
    }
    tokenReq.bodyFields = query;
    final res = JsonDecoder().convert(await (await tokenReq.send()).stream.bytesToString());
    final result = _validateAndSetFields(res);
    _timeStamp = DateTime.now();
    return result;
  }

  /// Save the token.
  /// [id] is used to uniquely identify the acccess token.
  /// If [allowOverwrite] is true, the function may overwrite existing token.
  Future<bool> saveToken({@required String id, String storeId, bool allowOverwrite = true}) => AccessTokenStore.fromId(storeId).saveToken(token: this, id: id, allowOverwrite: allowOverwrite);

  /// Create a new HTTP request with bearer token. The function may refresh the token if needed.
  /// [method] is either `GET`, `POST`, `PUT`, or ...
  Future<Request> createRequest(String method, Uri uri) async {
    await refreshIfNeeded();
    final req = Request(method, uri);
    req.headers['Authorization'] = 'Bearer $accessToken';
    return req;
  }

  /// Fetch (`GET`) the specified URL.
  Future<ByteStream> getByteStreamFromUri(Uri uri) async => (await (await createRequest('GET', uri)).send()).stream;

  /// Fetch (`GET`) the specified URL.
  Future<String> getStringFromUri(Uri uri) async => await (await getByteStreamFromUri(uri)).bytesToString();

  /// Fetch (`GET`) the specified URL.
  Future<dynamic> getJsonFromUri(Uri uri) async => JsonDecoder().convert(await getStringFromUri(uri));

  ///  high-entropy cryptographic random string defined [RFC7636 Section 4.1](https://tools.ietf.org/html/rfc7636#section-4.1).
  static String _cryptRandom(int length) {
    // https://tools.ietf.org/html/rfc3986#section-2.3
    const chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._~';
    final rand = Random.secure();
    final sb = StringBuffer();
    for (int i = 0; i < length; i++)
      sb.write(chars[rand.nextInt(chars.length)]);
    return sb.toString();
  }

  static String _sha256str(String random) => base64Url.encode(sha256.newInstance().convert(random.codeUnits).bytes);
}

/// Cache for [AccessToken] instances.
/// It is implemented upon iOS's [Keychain](https://developer.apple.com/documentation/security/keychain_services#//apple_ref/doc/uid/TP30000897-CH203-TP1) or Android's [Keystore](https://developer.android.com/training/articles/keystore.html).
class AccessTokenStore {

  /// Used to select a credential store. It can be null and the default store is selected. It may be any string that uniquely identify the store.
  final String storeId;

  AccessTokenStore._({this.storeId});

  static AccessTokenStore fromId(String storeId) => AccessTokenStore._(storeId: storeId ?? '');

  String get _storePrefix => storeId != null ? '~oauth2~$storeId~' : '~!oauth2!~global~';

  /// Get all saved tokens. If no token is saved, or no such store found, the function returns empty Map.
  Future<Map<String, AccessToken>> getSavedTokens() async {
    final storePrefix = _storePrefix;
    final storage = FlutterSecureStorage();
    final allValues = await storage.readAll();
    return Map.fromEntries(allValues.entries.where((e) => e.key.startsWith(storePrefix)).map((e) => MapEntry(e.key.substring(storePrefix.length), AccessToken.deserialize(e.value))));
  }

  /// Get saved token of the specified [id] if available; otherwise null.
  Future<AccessToken> getSavedToken({@required String id}) async {
    final storePrefix = _storePrefix;
    final storage = FlutterSecureStorage();
    return AccessToken.deserialize(await storage.read(key: storePrefix + id));
  }

  /// Remove tokens of specified IDs.
  Future<void> removeSavedTokens({@required Iterable<String> ids}) async {
    final storePrefix = _storePrefix;
    final storage = FlutterSecureStorage();
    for (var id in ids) {
      await storage.delete(key: storePrefix + id);
    }
  }

  /// Remove all saved tokens.
  Future<void> removeAllSavedTokens() async {
    final storePrefix = _storePrefix;
    final storage = FlutterSecureStorage();
    final allValues = await storage.readAll();
    for (var key in allValues.keys.where((key) => key.startsWith(storePrefix))) {
      await storage.delete(key: key);
    }
  }

  /// Save the token.
  /// [id] is used to uniquely identify the acccess token.
  /// If [allowOverwrite] is true, the function may overwrite existing token.
  Future<bool> saveToken({@required AccessToken token, @required String id, bool allowOverwrite = true}) async {
    final key = _storePrefix + id;
    final storage = FlutterSecureStorage();
    if (!allowOverwrite && (await storage.read(key: key)) != null) {
      return false;
    }
    await storage.write(key: key, value: token.serialize());
    return true;
  }
}
