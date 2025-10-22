Pod::Spec.new do |s|
  s.name             = 'Flutter'
  s.version          = '1.0.0'
  s.summary          = 'Prebuilt Flutter iOS Engine Framework'
  s.description      = 'Codemagic-safe local podspec'
  s.homepage         = 'https://flutter.dev'
  s.license          = { :type => 'BSD' }
  s.author           = { 'Flutter Dev' => 'flutter-dev@googlegroups.com' }
  s.source           = { :path => '.' }
  s.ios.deployment_target = '13.0'
  s.vendored_frameworks = 'App.xcframework'
end
