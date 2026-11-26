# Uncomment the next line to define a global platform for your project
platform :ios, '15.0'

target 'Notes' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!
  
  # Pods for Whirlpost
  
  pod 'Protobuf', '= 3.22.1'
  pod 'TPKeyboardAvoiding'
  #    pod 'Toaster'
  pod 'TOPasscodeViewController', '= 0.0.2'
  pod 'TTTAttributedLabel'
  pod 'Firebase'
  pod 'FirebaseCore'
  pod 'FirebaseAuth'
  pod 'FirebaseUI'
  pod 'Firebase/Database'
  #pod 'Firebase/AdMob'
  pod 'FBSDKLoginKit'
  pod 'SwiftyStoreKit'
  pod 'ReachabilitySwift', '~> 3'
  pod 'MBProgressHUD'
  pod 'SCLAlertView'
  pod 'Toast-Swift'
  # for social app
  pod 'Firebase/Messaging'
  pod 'Firebase/Firestore'
  pod 'Firebase/Storage'
  pod 'Firebase/RemoteConfig'
  pod 'Firebase/Performance'
  #    pod 'FirebaseUI', '~> 5.0'
  pod 'Fabric', '~> 1.7.11'
  # pod 'Crashlytics', '~> 3.10.7'
  pod 'SDWebImage'
  pod 'SwiftHEXColors'
  pod 'DateToolsSwift'
  pod 'FBSDKCoreKit'
  pod 'Google-Mobile-Ads-SDK'
  
end
post_install do |installer|
  installer.pods_project.targets.each do |target|
    if target.name == 'BoringSSL-GRPC'
      target.source_build_phase.files.each do |file|
        if file.settings && file.settings['COMPILER_FLAGS']
          flags = file.settings['COMPILER_FLAGS'].split
          flags.reject! { |flag| flag == '-GCC_WARN_INHIBIT_ALL_WARNINGS' }
          file.settings['COMPILER_FLAGS'] = flags.join(' ')
        end
      end
    end
  end
        installer.pods_project.build_configurations.each do |config|
          config.build_settings["EXCLUDED_ARCHS[sdk=iphonesimulator*]"] = "arm64"
        end
        installer.pods_project.targets.each do |target|
          target.build_configurations.each do |config|
            config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15'
          end
        end
        installer.pods_project.targets.each do |target|
            target.build_configurations.each do |config|
            xcconfig_path = config.base_configuration_reference.real_path
            xcconfig = File.read(xcconfig_path)
            xcconfig_mod = xcconfig.gsub(/DT_TOOLCHAIN_DIR/, "TOOLCHAIN_DIR")
            File.open(xcconfig_path, "w") { |file| file << xcconfig_mod }
            end
        end
  # Preserve device/release linking. Fabric is unused by app code and has no
  # arm64-simulator slice, so omit only that binary for Debug simulator builds.
  debug_config = installer.sandbox.root.join('Target Support Files', 'Pods-Notes', 'Pods-Notes.debug.xcconfig')
  if File.exist?(debug_config)
    contents = File.read(debug_config)
    contents = contents.gsub('-framework "Fabric"', '$(APPLAZ_LEGACY_FABRIC_LINK_FLAGS)')
    unless contents.include?('APPLAZ_LEGACY_FABRIC_LINK_FLAGS[sdk=iphonesimulator*]')
      contents += "\nAPPLAZ_LEGACY_FABRIC_LINK_FLAGS = -framework \"Fabric\"\nAPPLAZ_LEGACY_FABRIC_LINK_FLAGS[sdk=iphonesimulator*] =\n"
    end
    File.write(debug_config, contents)
  end
end
