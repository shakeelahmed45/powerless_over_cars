# --------------------------------------------------------------------
#  Flutter CocoaPods helper (shim for Flutter 3.35+)
#  This loads the real logic from your installed Flutter SDK.
# --------------------------------------------------------------------

flutter_bin = `which flutter`.strip
abort("❌ Flutter not found on PATH") if flutter_bin.nil? || flutter_bin.empty?

# Determine Flutter SDK root
flutter_root = File.expand_path("../../", File.dirname(flutter_bin))

# Load the CocoaPods integration from the Flutter SDK
cocoapods_helper = File.join(flutter_root, "packages", "flutter_tools", "lib", "src", "macos", "cocoapods.rb")
abort("❌ Could not locate Flutter CocoaPods helper at #{cocoapods_helper}") unless File.exist?(cocoapods_helper)

require cocoapods_helper
