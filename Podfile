# Uncomment the next line to define a global platform for your project
  platform :macos, '15.0'

target 'WSAdmin' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for WSAdmin
    pod 'GoogleSignIn'
    pod 'GoogleSignInSwiftSupport'
    pod 'GoogleAPIClientForREST/Sheets'
    pod 'GoogleAPIClientForREST/Drive'
#    pod 'AppAuth'
  

    post_install do |installer|
      installer.pods_project.targets.each do |target|
          target.build_configurations.each do |config|
            config.build_settings['MACOSX_DEPLOYMENT_TARGET'] = '15.0'
          end
        end
    end
    end
