# Robust Flutter CocoaPods helper (vendored in repo)
# - Guarantees Flutter engine pod is added
# - Resolves plugin pods from .flutter-plugins-dependencies
# - Handles both `ios/` and `darwin/` podspec locations

require 'json'
require 'fileutils'

def _run(cmd)
  puts("→ #{cmd}")
  system(cmd) or raise "Command failed: #{cmd}"
end

def _upper_mode
  mode = (ENV['FLUTTER_BUILD_MODE'] || ENV['CONFIGURATION'] || 'release').downcase
  case mode
  when 'debug'   then 'Debug'
  when 'profile' then 'Profile'
  else                'Release'
  end
end

def flutter_ios_podfile_setup
  # no-op (parity with Flutter’s template)
end

def flutter_install_all_ios_pods(app_path)
  engine_root   = File.expand_path(File.join(app_path, 'Flutter'))
  mode_dir      = File.join(engine_root, _upper_mode)
  podspec_path  = File.join(mode_dir, 'Flutter.podspec')

  # Ensure engine artifacts exist (idempotent and fast if cached)
  unless File.exist?(podspec_path)
    # Try to (pre)fetch iOS engine, then build once to generate the podspec
    _run('flutter --suppress-analytics precache --ios')
    _run('flutter --suppress-analytics pub get')
    # a light build is enough to materialize Flutter.podspec
    _run("flutter --suppress-analytics build ios --no-codesign --#{_upper_mode.downcase}")
  end

  # Add the Flutter pod (path-based dev pod so no CDN fetch)
  unless File.exist?(podspec_path)
    raise "Flutter.podspec not found at #{podspec_path}"
  end
  pod 'Flutter', :path => engine_root

  # Add plugin pods
  deps_file = File.expand_path(File.join(app_path, '..', '.flutter-plugins-dependencies'))
  return unless File.exist?(deps_file)

  deps = JSON.parse(File.read(deps_file))
  ios_plugins = (deps['plugins'] || {})['ios'] || []

  ios_plugins.each do |pl|
    name = pl['name']
    pkg_root = File.expand_path(File.join(app_path, '..', pl['path']))

    paths_to_try = [
      File.join(pkg_root, 'ios', "#{name}.podspec"),
      File.join(pkg_root, 'darwin', "#{name}.podspec"),
      File.join(pkg_root, "#{name}.podspec")
    ]

    pod_path = nil
    paths_to_try.each do |ps|
      if File.exist?(ps)
        pod_path = File.dirname(ps)
        break
      end
    end

    if pod_path.nil?
      # Fallback: if plugin has ios/ folder but no podspec at expected names,
      # still try path install (some plugins generate podspecs on the fly)
      if Dir.exist?(File.join(pkg_root, 'ios'))
        pod_path = File.join(pkg_root, 'ios')
      elsif Dir.exist?(File.join(pkg_root, 'darwin'))
        pod_path = File.join(pkg_root, 'darwin')
      else
        puts "⚠️  Skipping #{name}: no podspec found at expected locations"
        next
      end
    end

    puts "✅ Adding plugin pod #{name} from #{pod_path}"
    pod name, :path => pod_path
  end
end

def flutter_additional_ios_build_settings(target)
  target.build_configurations.each do |config|
    config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] ||= '13.0'
    config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] ||= 'arm64'
    config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] ||= 'YES'
    config.build_settings['SWIFT_VERSION'] ||= '5.0'
  end
end
