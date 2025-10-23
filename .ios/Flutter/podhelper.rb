# Enhanced Flutter CocoaPods helper (final Bitrise-compatible version)
# Handles absolute plugin paths, nested podspecs, and CI environments.

require 'json'
require 'pathname'
require 'find'

def flutter_ios_podfile_setup
  # Placeholder for Flutter compatibility
end

def flutter_install_all_ios_pods(app_path)
  # 1️⃣ Flutter engine pod (local)
  config = ENV['CONFIGURATION'] || 'Release'
  engine_dir = File.expand_path(File.join(app_path, 'Flutter', config))
  engine_podspec = File.join(engine_dir, 'Flutter.podspec')
  pod 'Flutter', :path => engine_dir if File.exist?(engine_podspec)

  # 2️⃣ Load Flutter plugin dependencies
  plugin_file = File.expand_path(File.join(app_path, '..', '.flutter-plugins-dependencies'))
  unless File.exist?(plugin_file)
    puts "⚠️  .flutter-plugins-dependencies not found. Run `flutter pub get` first."
    return
  end

  deps = JSON.parse(File.read(plugin_file))
  ios_plugins = (deps['plugins'] || {})['ios'] || []

  ios_plugins.each do |pl|
    name = pl['name']
    plugin_path_from_flutter = pl['path']
    path_obj = Pathname.new(plugin_path_from_flutter)

    # ✅ Handle absolute + relative plugin paths
    plugin_root = if path_obj.absolute?
      plugin_path_from_flutter
    else
      File.expand_path(File.join(app_path, '..', plugin_path_from_flutter))
    end

    ios_dir = File.join(plugin_root, 'ios')
    root_podspec = File.join(plugin_root, "#{name}.podspec")
    ios_podspec  = File.join(ios_dir, "#{name}.podspec")

    # ✅ Try all likely podspec locations
    if File.exist?(ios_podspec)
      pod name, :path => ios_dir
    elsif File.exist?(root_podspec)
      pod name, :path => plugin_root
    else
      found_podspec = nil
      Find.find(plugin_root) do |path|
        if File.basename(path) == "#{name}.podspec"
          found_podspec = File.dirname(path)
          break
        end
      end
      if found_podspec
        pod name, :path => found_podspec
      else
        puts "⚠️  Podspec not found for #{name} — looked in #{plugin_root}"
      end
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
