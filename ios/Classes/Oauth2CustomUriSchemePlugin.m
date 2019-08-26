#import "Oauth2CustomUriSchemePlugin.h"
#import <oauth2_custom_uri_scheme/oauth2_custom_uri_scheme-Swift.h>

@implementation Oauth2CustomUriSchemePlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftOauth2CustomUriSchemePlugin registerWithRegistrar:registrar];
}
@end
