require 'json'
require 'fileutils'
require 'open3'

def flutter_ios_podfile_setup
  # no-op
end

def _engine_dir(ios_application_path)
  File.expand_path(File.join(ios_application_path, 'Flutter'))
end

def _project_podspec(ios_application_path)
  File.join(_engine_dir(ios_application_path), 'Flutter.podspec')
end

def _flutter_root
  env = ENV['FLUTTER_ROOT']
  return env unless env.nil? || env.empty?
  which, _ = Open3.capture2('which flutter')
  path = which.strip
  return nil if path.empty?
  File.expand_path(File.join(File.dirname(path), '..'))
end

def _sdk_podspec
  root = _flutter_root
  return nil if root.nil? || root.empty?
  File.join(root, 'bin', 'cache', 'artifacts', 'engine', 'ios', 'Flutter.podspec')
end

def _ensure_project_podspec(ios_application_path)
  proj = _project_podspec(ios_application_path)
  return if File.exist?(proj)

  sdk = _sdk_podspec
  if sdk && File.exist?(sdk)
    FileUtils.mkdir_p(File.dirname(proj))
    FileUtils.cp(sdk, proj)
    Pod::UI.puts "✅ Copied Flutter.podspec from SDK cache to #{proj}"
  else
    raise <<~EOS
      ❌ Flutter.podspec not found at:
         #{proj}
      And SDK podspec not found at:
         #{sdk || '(unknown)'}
      Fix (in project root):
        1) flutter precache --ios
        2) flutter pub get
        3) flutter build ios --no-codesign
      Then:
        cd ios && pod install
    EOS
  end
end

def flutter_install_all_ios_pods(ios_application_path)
  _ensure_project_podspec(ios_application_path)

  engine_dir = _engine_dir(ios_application_path)
  pod 'Flutter', :path => engine_dir

  deps_file = File.expand_path(File.join(ios_application_path, '..', '.flutter-plugins-dependencies'))
  return unless File.exist?(deps_file)

  deps = JSON.parse(File.read(deps_file)) rescue {}
  ios_plugins = (deps['plugins'] || {})['ios'] || []

  ios_plugins.each do |pl|
    name = pl['name']
    raw_path = pl['path'] || ''
    pkg_root = raw_path.start_with?('/') ? raw_path : File.expand_path(File.join(ios_application_path, '..', raw_path))

    candidates = [
      File.join(pkg_root, 'ios', "#{name}.podspec"),
      File.join(pkg_root, 'darwin', "#{name}.podspec"),
      File.join(pkg_root, "#{name}.podspec"),
    ]

    pod_path =
      if File.exist?(candidates[0]) then File.dirname(candidates[0])
      elsif File.exist?(candidates[1]) then File.dirname(candidates[1])
      elsif File.exist?(candidates[2]) then File.dirname(candidates[2])
      elsif Dir.exist?(File.join(pkg_root, 'ios')) then File.join(pkg_root, 'ios')
      elsif Dir.exist?(File.join(pkg_root, 'darwin')) then File.join(pkg_root, 'darwin')
      else
        Pod::UI.warn("⚠️  Skipping #{name}: no podspec/ios/darwin under #{pkg_root}")
        nil
      end

    if pod_path
      Pod::UI.puts "✅ Adding plugin pod #{name} from #{pod_path}"
      pod(name, :path => pod_path)
    end
  end
end

def flutter_additional_ios_build_settings(installer)
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['SWIFT_VERSION'] ||= '5.0'
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] ||= '13.0'
      config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] ||= 'arm64'
      config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] ||= 'YES'
    end
  end
end
