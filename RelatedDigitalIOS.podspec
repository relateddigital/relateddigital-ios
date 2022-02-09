Pod::Spec.new do |s|
  s.name             = 'RelatedDigitalIOS'
  s.module_name      = 'RelatedDigitalIOS'
  s.version          = '1.0.0'
  s.summary          = 'RelatedDigitalIOS'
  s.description      = 'RelatedDigitalIOS'
  s.homepage         = 'https://www.relateddigital.com'
  s.license          = 'Apache License, Version 2.0'
  s.swift_version    = '5.0'
  s.author           = { 'Related Digital' => 'developer@relateddigital.com' }
  s.source           = { git: 'https://github.com/relateddigital/relateddigital-ios.git', tag: s.version.to_s }
  s.ios.deployment_target = '10.0'
  s.source_files  = ['Sources/**/*.{swift,h,m,xib}']
  s.resources    = ['Sources/Assets/**/*.{html,js,png}']
  s.ios.pod_target_xcconfig = { 'PRODUCT_BUNDLE_IDENTIFIER': 'com.relateddigital.relateddigitalios'}
  s.requires_arc     = true
end