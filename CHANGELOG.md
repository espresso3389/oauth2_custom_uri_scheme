## 0.3.11

- ASWebAuthenticationSession.start sliently fails on iOS13 due to breaking changes.

## 0.3.10

**TEMPORARY RELEASE**

Because 0.3.7 - 0.3.9 breaks consistency on certain environment, 0.3.10 is just a copy of 0.3.6 and has known issues #5.

Until flutter_inappwebview's next release, I could not release a new version.........
https://github.com/pichillilorenzo/flutter_inappwebview/issues/220#issuecomment-580783367

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
