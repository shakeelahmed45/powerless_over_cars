# Improved Flutter CocoaPods helper supporting iOS/darwin plugin structures

require 'json'

def flutter_ios_podfile_setup
  # placeholder to keep parity with Flutter's default pod helper
end

def flutter_install_all_ios_pods(app_path)
  config = ENV['CONFIGURATION'] || 'Release'
  engine_dir = File.expand_path(File.join(app_path, 'Flutter', config))
  engine_podspec = File.join(engine_dir, 'Flutter.podspec')

  # Add Flutter engine pod if it exists locally
  pod 'Flutter', :path => engine_dir if File.exist?(engine_podspec)

  # Load plugin dependencies
  plugin_file = File.expand_path(File.join(app_path, '..', '.flutter-plugins-dependencies'))
  return unless File.exist?(plugin_file)

  deps = JSON.parse(File.read(plugin_file))
  ios_plugins = (deps['plugins'] || {})['ios'] || []

  ios_plugins.each do |pl|
    name = pl['name']
    root = File.expand_path(File.join(app_path, '..', pl['path']))

    # Check common plugin structures
    candidate_paths = [
      File.join(root, 'ios', "#{name}.podspec"),
      File.join(root, 'darwin', "#{name}.podspec"),
      File.join(root, "#{name}.podspec")
    ]

    found_path = candidate_paths.find { |p| File.exist?(p) }

    if found_path
      pod name, :path => File.dirname(found_path)
    else
      puts "⚠️  Could not find podspec for #{name} in any known location"
    end
  end
end

def flutter_additional_ios_build_settings(target)
  target.build_configurations.each do |config|
    config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] ||= '13.0'
    config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] ||= 'YES'
    config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] ||= 'arm64'
  end
end
