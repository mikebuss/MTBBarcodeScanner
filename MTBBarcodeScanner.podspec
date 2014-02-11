Pod::Spec.new do |s|
  s.name             = "MTBBarcodeScanner"
  s.version          = "0.1.0"
  s.summary          = "A lightweight, easy-to-use barcode scanning library for iOS 7."
  s.homepage         = "https://github.com/mikebuss/MTBBarcodeScanner"
  s.license          = 'MIT'
  s.author           = { "Mike Buss" => "mike@mikebuss.com" }
  s.source           = { :git => "git@github.com:mikebuss/MTBBarcodeScanner.git", :tag => s.version.to_s }

  s.platform     = :ios, '7.0'
  s.ios.deployment_target = '7.0'
  s.requires_arc = true

  s.source_files = 'Classes'
  s.resources = 'Assets'

  s.ios.exclude_files = 'Classes/osx'
  s.osx.exclude_files = 'Classes/ios'
  
  # s.public_header_files = 'Classes/**/*.h'
  
  s.frameworks = 'AVFoundation', 'QuartzCore'
  
  # s.dependency 'JSONKit', '~> 1.4'
  
end
