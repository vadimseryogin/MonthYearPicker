#
# Be sure to run `pod lib lint MonthYearPicker.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "MonthYearPicker"
  s.version          = "4.0.0"
  s.summary          = "A UIControl subclass that allows users to select month and year"
  s.description      = <<-DESC
    `UIDatePicker` doesn't have a mode for month/year, which is commonly used
in credit card forms. MonthYearPicker is a `UIControl` subclass that displays
 localised months and years.
                       DESC
  s.homepage         = "https://github.com/alexanderedge/MonthYearPicker"
  s.license          = 'MIT'
  s.author           = { "Alexander Edge" => "alex@alexedge.co.uk" }
  s.source           = { :git => "https://github.com/alexanderedge/MonthYearPicker.git", :tag => s.version.to_s }
  s.swift_version = '5.2'
  s.platform     = :ios, '9.0'
  s.source_files = 'Sources/**/*'
  s.frameworks = 'UIKit'
end
