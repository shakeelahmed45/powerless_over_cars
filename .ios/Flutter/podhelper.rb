require 'json'

def flutter_ios_podfile_setup
  # placeholder for compatibility
end

def flutter_install_all_ios_pods(app_path)
  config = ENV['CONFIGURATION'] || 'Release'
  engine_dir = File.expand_path(File.join(app_path, 'Flutter', config))
  engine_podspec = File.join(engine_dir, 'Flutter.podspec')
  pod 'Flutter', :path => engine_dir if File.exist?(engine_podspec)

  plugin_file = File.expand_path(File.join(app_path, '..', '.flutter-plugins-dependencies'))
  return unless File.exist?(plugin_file)

  deps = JSON.parse(File.read(plugin_file))
  ios_plugins = (deps['plugins'] || {})['ios'] || []

  ios_plugins.each do |pl|
    name = pl['name']
    path = File.expand_path(File.join(app_path, '..', pl['path']))

    # ✅ Fix for CI (Bitrise)
    podspec_paths = [
      File.join(path, 'ios', "#{name}.podspec"),
      File.join(path, 'darwin', "#{name}.podspec"),
      File.join(path, "#{name}.podspec")
    ]

    valid_path = podspec_paths.find { |p| File.exist?(p) }
    if valid_path
      pod name, :path => File.dirname(valid_path)
    else
      puts "⚠️  Podspec not found for #{name} — checked #{podspec_paths.join(', ')}"
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
