# Improved Flutter CocoaPods helper for Bitrise & local builds
# Handles new plugin layouts (ios/ and darwin/)
require 'json'

def flutter_ios_podfile_setup
  # Keep placeholder for Flutter parity
end

def flutter_install_all_ios_pods(app_path)
  config = ENV['CONFIGURATION'] || 'Release'
  engine_dir = File.expand_path(File.join(app_path, 'Flutter', config))
  engine_podspec = File.join(engine_dir, 'Flutter.podspec')

  # Use prebuilt Flutter engine if available
  if File.exist?(engine_podspec)
    pod 'Flutter', :path => engine_dir
  else
    puts "⚠️  Flutter engine podspec not found in #{engine_dir}"
  end

  # Read plugin dependencies
  plugin_file = File.expand_path(File.join(app_path, '..', '.flutter-plugins-dependencies'))
  unless File.exist?(plugin_file)
    puts "⚠️  No .flutter-plugins-dependencies file found at #{plugin_file}"
    return
  end

  deps = JSON.parse(File.read(plugin_file))
  ios_plugins = (deps['plugins'] || {})['ios'] || []

  ios_plugins.each do |pl|
    name = pl['name']
    root = File.expand_path(File.join(app_path, '..', pl['path']))

    # Try multiple possible podspec locations
    possible_paths = [
      File.join(root, 'ios', "#{name}.podspec"),
      File.join(root, 'darwin', "#{name}.podspec"),
      File.join(root, "#{name}.podspec")
    ]

    podspec_path = possible_paths.find { |p| File.exist?(p) }

    if podspec_path
      pod name, :path => File.dirname(podspec_path)
      puts "✅ Found podspec for #{name} at #{podspec_path}"
    else
      puts "❌ No podspec found for #{name}. Tried:"
      possible_paths.each { |p| puts "   - #{p}" }
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
