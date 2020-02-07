## 0.3.10

* Mmm, recent commits loses consistency on the repo...

## 0.3.9

* FIXED: #4, #5: Now uses flutter_inappwebview rather than flutter_custom_tabs to control tab closing timing.
* Document updates.

## 0.3.7

* ~~FIXED: #5 Workaround for java.lang.UnsupportedOperationException: The new embedding does not support the old FlutterView. at io.flutter.embedding.engine.plugins.shim.ShimRegistrar.view(ShimRegistrar.java:82)~~
* More realistic example for Microsoft Account.

## 0.3.6

* token endpoint also needs redirect_uri.

## 0.3.5

* code_challenge is not correctly calculated.

## 0.3.4

* `refresh` throws exception if it could not refresh the token.
* Add `AccessToken.printHandler` static variable to customize debug log verbosity.

## 0.3.2

* `OAuth2Config.authorize`: reset should be false by default.

## 0.3.1

* Minor updates.

## 0.3.0

* **BREAKING CHANGE**: `OAuth2Config` is moved to `oauth2_custom_uri_scheme.dart`.
* Add several helper methods for POST/PUT requests.

## 0.2.0

* Introducing easy to use widgets; `OAuth2Config` and `OAuth2TokenHolder`.

## 0.1.1

* Fix build issue on iOS caused by podspec.
