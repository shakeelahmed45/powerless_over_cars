# Minimal Flutter CocoaPods helper kept locally in the repo.
# - Uses prebuilt Flutter engine if present (development pod via :path)
# - Installs plugins by reading .flutter-plugins-dependencies
# - Handles plugins whose .podspec is at package root (e.g. webview_flutter_wkwebview)

require 'json'

def flutter_ios_podfile_setup
  # Keep as a placeholder for parity with Flutter's template
end

def flutter_install_all_ios_pods(app_path)
  # 1) Engine (development pod) — only if a local Flutter.podspec exists
  config = ENV['CONFIGURATION'] || 'Release'
  engine_dir = File.expand_path(File.join(app_path, 'Flutter', config))
  engine_podspec = File.join(engine_dir, 'Flutter.podspec')
  if File.exist?(engine_podspec)
    # Use :path (development pod). This avoids any downloader errors.
    pod 'Flutter', :path => engine_dir
  end

  # 2) Plugins — read from .flutter-plugins-dependencies
  plugin_file = File.expand_path(File.join(app_path, '..', '.flutter-plugins-dependencies'))
  return unless File.exist?(plugin_file)

  deps = JSON.parse(File.read(plugin_file))
  ios_plugins = (deps['plugins'] || {})['ios'] || []

  ios_plugins.each do |pl|
    name = pl['name']
    # pl['path'] is relative to the project root (one level above ios/)
    root = File.expand_path(File.join(app_path, '..', pl['path']))
    ios_dir = File.join(root, 'ios')

    root_podspec = File.join(root, "#{name}.podspec")
    ios_podspec  = File.join(ios_dir, "#{name}.podspec")

    if File.exist?(ios_podspec)
      pod name, :path => ios_dir
    elsif File.exist?(root_podspec)
      # Some plugins (e.g., webview_flutter_wkwebview) keep the podspec at package root
      pod name, :path => root
    else
      # Last resort: try ios dir; most Flutter plugins place sources there
      pod name, :path => ios_dir
    end
  end
end

def flutter_additional_ios_build_settings(target)
  target.build_configurations.each do |config|
    # Common, non-invasive settings
    config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] ||= '13.0'
    config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] ||= 'YES'
    # Avoid simulator/arm64 friction
    config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] ||= 'arm64'
  end
end
