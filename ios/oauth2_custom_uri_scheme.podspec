#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'oauth2_custom_uri_scheme'
  s.version          = '0.0.1'
  s.summary          = 'A Flutter plugin that implements OAuth2 with custom URI scheme.'
  s.description      = <<-DESC
This plugin implements OAuth2+custom URI scheme using ASWebAuthenticationSession/SFAuthenticationSession and targetting iOS 11.0.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Takashi Kawasaki' => 'espresso3389@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'

  s.ios.deployment_target = 11.0'
end

