require "fileutils"
require "xcodeproj"

PROJECT_NAME = "MintRideSW".freeze
IOS_VERSION = "17.0".freeze
PROJECT_PATH = "#{PROJECT_NAME}.xcodeproj".freeze

FileUtils.rm_rf(PROJECT_PATH)

project = Xcodeproj::Project.new(PROJECT_PATH)
project.root_object.attributes["LastUpgradeCheck"] = "2600"
project.root_object.attributes["TargetAttributes"] = {}

app_target = project.new_target(:application, PROJECT_NAME, :ios, IOS_VERSION)
test_target = project.new_target(:unit_test_bundle, "#{PROJECT_NAME}Tests", :ios, IOS_VERSION)
test_target.add_dependency(app_target)

app_files = %w[
  MintRideSW/MintRideSWApp.swift
  MintRideSW/Models/AppSettings.swift
  MintRideSW/Models/TelemetryModels.swift
  MintRideSW/Managers/RunTrackerCore.swift
  MintRideSW/Managers/StopwatchEngine.swift
  MintRideSW/Managers/TelemetryManager.swift
  MintRideSW/Utilities/Formatters.swift
  MintRideSW/Views/BenchmarkTile.swift
  MintRideSW/Views/MainStopwatchView.swift
  MintRideSW/Views/MetricTile.swift
  MintRideSW/Views/SettingsView.swift
].freeze

test_files = %w[
  MintRideSWTests/MintRideSWTests.swift
].freeze

root_group = project.main_group
root_group.set_source_tree("<group>")

app_group = root_group.new_group("MintRideSW", "MintRideSW")
models_group = app_group.new_group("Models", "Models")
managers_group = app_group.new_group("Managers", "Managers")
utilities_group = app_group.new_group("Utilities", "Utilities")
views_group = app_group.new_group("Views", "Views")
tests_group = root_group.new_group("MintRideSWTests", "MintRideSWTests")

group_for_path = lambda do |path|
  case path
  when /Models\//
    models_group
  when /Managers\//
    managers_group
  when /Utilities\//
    utilities_group
  when /Views\//
    views_group
  when /MintRideSWTests\//
    tests_group
  else
    app_group
  end
end

app_files.each do |path|
  file_ref = group_for_path.call(path).new_file(File.basename(path))
  app_target.add_file_references([file_ref])
end

test_files.each do |path|
  file_ref = tests_group.new_file(File.basename(path))
  test_target.add_file_references([file_ref])
end

app_group.new_file("Info.plist")

app_target.build_configurations.each do |config|
  config.build_settings["PRODUCT_BUNDLE_IDENTIFIER"] = "com.luca.#{PROJECT_NAME}"
  config.build_settings["INFOPLIST_FILE"] = "MintRideSW/Info.plist"
  config.build_settings["SWIFT_VERSION"] = "6.0"
  config.build_settings["IPHONEOS_DEPLOYMENT_TARGET"] = IOS_VERSION
  config.build_settings["TARGETED_DEVICE_FAMILY"] = "1,2"
  config.build_settings["CODE_SIGN_STYLE"] = "Automatic"
  config.build_settings["CURRENT_PROJECT_VERSION"] = "1"
  config.build_settings["MARKETING_VERSION"] = "1.0"
  config.build_settings["GENERATE_INFOPLIST_FILE"] = "NO"
  config.build_settings["ASSETCATALOG_COMPILER_APPICON_NAME"] = ""
  config.build_settings["SWIFT_EMIT_LOC_STRINGS"] = "NO"
end

test_target.build_configurations.each do |config|
  config.build_settings["PRODUCT_BUNDLE_IDENTIFIER"] = "com.luca.#{PROJECT_NAME}Tests"
  config.build_settings["IPHONEOS_DEPLOYMENT_TARGET"] = IOS_VERSION
  config.build_settings["SWIFT_VERSION"] = "6.0"
  config.build_settings["TARGETED_DEVICE_FAMILY"] = "1,2"
  config.build_settings["GENERATE_INFOPLIST_FILE"] = "YES"
  config.build_settings["TEST_HOST"] = "$(BUILT_PRODUCTS_DIR)/#{PROJECT_NAME}.app/#{PROJECT_NAME}"
  config.build_settings["BUNDLE_LOADER"] = "$(TEST_HOST)"
end

scheme = Xcodeproj::XCScheme.new
scheme.configure_with_targets(app_target, test_target)
scheme.set_launch_target(app_target)
scheme.save_as(PROJECT_PATH, PROJECT_NAME, true)

project.save
