# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

project 'SmashMatch.xcodeproj'
target 'SmashMatch' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for SmashMatch
  pod 'SQLite.swift', '~> 0.11.4'
  pod 'SwiftySKScrollView'

  post_install do |installer| installer.pods_project.build_configurations.each do |config| config.build_settings['PROVISIONING_PROFILE_SPECIFIER'] = '' end end

end
