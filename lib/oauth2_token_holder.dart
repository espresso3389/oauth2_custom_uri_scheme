import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:rxdart/rxdart.dart';

import 'oauth2_custom_uri_scheme.dart';

/// if [reset] is true, authorization clears the cache before authorization and it always do interactive authorization.
typedef Authorize = Future<AccessToken?> Function({bool reset});
typedef Deauthorize = Future<void> Function();

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
  /// [deauthorize] is a function that can be used to deauthorize the app; if revocation is supported, it also revokes the tokens. Please note that [deauthorize] does not interact with user before deauthorization.
  final Widget Function(BuildContext context, AccessToken? accessToken, OAuth2TokenAvailability availability,
      Authorize authorize, Deauthorize deauthorize, Widget? child) builder;
  final Widget? child;

  OAuth2TokenHolder({required this.config, required this.builder, this.child});
}

class _OAuth2TokenHolderState extends State<OAuth2TokenHolder> {
  static final _tokenSubjects = Map<String, BehaviorSubject<AccessToken?>>();

  late BehaviorSubject<AccessToken?> _tokenSubject;
  OAuth2TokenAvailability _availability = OAuth2TokenAvailability.NotAvailable;

  @override
  void initState() {
    _tokenSubject = _tokenSubjects.putIfAbsent(widget.config.uniqueId, () => BehaviorSubject<AccessToken?>());
    loadFromCache();
    super.initState();
  }

  @override
  void didUpdateWidget(OAuth2TokenHolder oldWidget) {
    super.didUpdateWidget(oldWidget);
    _tokenSubject = _tokenSubjects.putIfAbsent(widget.config.uniqueId, () => BehaviorSubject<AccessToken?>());
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

  Future<AccessToken?> authorize({bool reset = true}) async {
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
    await accessToken?.revoke();
    await widget.config.reset();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AccessToken?>(
        stream: _tokenSubject.stream,
        builder: (context, snapshot) =>
            widget.builder(context, snapshot.data, _availability, authorize, deauthorize, widget.child));
  }
}
