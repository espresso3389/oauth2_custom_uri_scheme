## 1.0.0-alpha

* First version that support null-safety (Not yet fully tested).

## 0.4.6/0.4.7

* AccessToken.authorize introduces usePkce (the default is true) parameter to support certain IdP that does not support PKCE but return errors on PKCE related fields.

## 0.4.5

* Fixes stack overflow on accessing AccessToken.authorizationType.

## 0.4.4

* Update dependency packages.

## 0.4.3

* Fixes "Getting error after authorization- Failed to handle method call" (#5) completely using flutter_inappwebview 4.0.0.

## 0.4.2

* Improve error handling.
* Add AccessToken.authorizationType to use custom Authorization header with certain services.

## 0.4.1

* Protect against race-conditions on token refresh.

## 0.4.0

* Replacing Chrome Tab implementation.

## 0.3.12

* Just a documentation update.

## 0.3.11

* ASWebAuthenticationSession.start silently fails on iOS13 due to breaking changes.

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
