
import 'package:flutter/cupertino.dart';
import 'package:rxdart/rxdart.dart';

import 'oauth2_custom_uri_scheme.dart';

typedef Authorize = Future<AccessToken> Function({bool reset});
typedef Deauthorize = Future<void> Function();

/// [OAuth 2.0 (RFC 6749)](https://tools.ietf.org/html/rfc6749) configuration.
class OAuth2Config {
  /// ID to uniquely identify the usage of the access token. It is also used as an ID for caching the access token.
  final String uniqueId;
  final Uri authorizationEndpoint;
  final Uri tokenEndpoint;
  final Uri revocationEndpoint;
  final Uri redirectUri;
  final String clientId;
  final String clientSecret;
  final String login;
  /// Space delimited scope values. Mutually exclusive with [scopes].
  final String scope;
  /// Scope values. Mutually exclusive with [scope].
  final List<String> scopes;
  final bool useBasicAuth;
  /// Additional query params that are not directly supported by the plugin.
  final Map<String, String> additionalQueryParams;
  final String storeId;
  final OAuth2ResponseCallback responseCallback;

  OAuth2Config({@required this.uniqueId, @required this.authorizationEndpoint, @required this.tokenEndpoint, this.revocationEndpoint, @required this.redirectUri, @required this.clientId, @required this.clientSecret, this.login, this.scope, this.scopes, this.useBasicAuth = true, this.additionalQueryParams, this.storeId, this.responseCallback});

  Future<AccessToken> getAccessTokenFromCache() => AccessTokenStore.fromId(storeId).getSavedToken(id: uniqueId);

  Future<AccessToken> authorize({bool reset = true}) async {
    if (reset) {
      await AccessTokenStore.fromId(storeId).removeSavedTokens(ids: [uniqueId]);
    }
    return await AccessToken.authorize(
      authorizationEndpoint: authorizationEndpoint,
      tokenEndpoint: tokenEndpoint,
      revocationEndpoint: revocationEndpoint,
      redirectUri: redirectUri,
      clientId: clientId,
      clientSecret: clientSecret,
      login: login,
      scope: scope,
      scopes: scopes,
      useBasicAuth: useBasicAuth,
      additionalQueryParams: additionalQueryParams,
      idForCache: uniqueId,
      storeId: storeId,
      responseCallback: responseCallback);
  }

  /// Delete cached token.
  Future<void> reset() => AccessTokenStore.fromId(storeId).removeSavedTokens(ids: [uniqueId]);
}

enum OAuth2TokenAvailability {
  NotAvailable,
  Authorizing,
  Available,
}

class OAuth2TokenHolder extends StatefulWidget {
  @override
  _OAuth2TokenHolderState createState() => _OAuth2TokenHolderState();

  final OAuth2Config config;
  /// [accessToken] is either valid access token or null.
  /// [availability] indicate the current access token availability status.
  /// [authorize] is a function that can be used to authorize the app.
  /// [deauthorize] is a function that can be used to deauthorize the app; if revocation is supported, it also revokes the tokens.
  final Widget Function(BuildContext context, AccessToken accessToken, OAuth2TokenAvailability availability, Authorize authorize, Deauthorize deauthorize, Widget child) builder;
  final Widget child;

  OAuth2TokenHolder({@required this.config, @required this.builder, this.child});
}

class _OAuth2TokenHolderState extends State<OAuth2TokenHolder> {

  static final _tokenSubjects = Map<String, BehaviorSubject<AccessToken>>();

  BehaviorSubject<AccessToken> _tokenSubject;
  OAuth2TokenAvailability _availability = OAuth2TokenAvailability.NotAvailable;

  @override
  void initState() {
    _tokenSubject = _tokenSubjects.putIfAbsent(widget.config.uniqueId, () => BehaviorSubject<AccessToken>());
    loadFromCache();
    super.initState();
  }

  @override
  void didUpdateWidget(OAuth2TokenHolder oldWidget) {
    super.didUpdateWidget(oldWidget);
    _tokenSubject = _tokenSubjects.putIfAbsent(widget.config.uniqueId, () => BehaviorSubject<AccessToken>());
    loadFromCache();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void loadFromCache() async {
    final accessToken = await widget.config.getAccessTokenFromCache();
    _availability = accessToken != null ? OAuth2TokenAvailability.Available : OAuth2TokenAvailability.NotAvailable;
    _tokenSubject.add(accessToken);
  }

  Future<AccessToken> authorize({bool reset = true}) async {
    var accessToken = await widget.config.getAccessTokenFromCache();
    if (reset) {
      _availability = OAuth2TokenAvailability.Authorizing;
      _tokenSubject.add(null);
    } else {
      _availability = OAuth2TokenAvailability.Authorizing;
      _tokenSubject.add(accessToken);
    }
    final newAccessToken = await widget.config.authorize(reset: reset);
    if (newAccessToken != null) {
      accessToken = newAccessToken;
    }
    _availability = accessToken != null ? OAuth2TokenAvailability.Available : OAuth2TokenAvailability.NotAvailable;
    _tokenSubject.add(accessToken);
    return accessToken;
  }

  Future<void> deauthorize() async {
    _availability = OAuth2TokenAvailability.NotAvailable;
    _tokenSubject.add(null);
    final accessToken = await widget.config.getAccessTokenFromCache();
    await accessToken.revoke();
    await widget.config.reset();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AccessToken>(
      stream: _tokenSubject.stream,
      builder: (context, snapshot) => widget.builder(context, snapshot.data, _availability, authorize, deauthorize, widget.child));
  }
}
