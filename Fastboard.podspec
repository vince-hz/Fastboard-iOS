Pod::Spec.new do |s|
  s.name             = 'Fastboard'
  s.version          = '1.0.0-beta.7'
  s.summary          = 'Quickly create a whiteboard interface for iOS'

  s.description      = <<-DESC
  High-level SDK for Whiteboard-iOS with UI.
  We recommend using Whiteboard-iOS directly if you need more customization,
                       DESC

  s.homepage         = 'https://github.com/netless-io/fastboard-iOS'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'yunshi' => 'xuyunshi@agora.io' }
  s.source           = { :git => 'https://github.com/netless-io/fastboard-iOS.git', :tag => s.version.to_s }

  s.swift_version = '5.0'
  s.ios.deployment_target = '10.0'
  
  s.subspec 'core' do |core|
    core.source_files = 'Fastboard/Classes/**/*'
    core.dependency 'Whiteboard'
    core.exclude_files = 'Fastboard/Classes/FPA/*'
    core.resource_bundles = {
      'Icons' => ['Fastboard/Assets/*.xcassets'],
      'LocalizedStrings' => ['Fastboard/Assets/*.lproj/*.strings']
    }
    core.frameworks = 'UIKit'
  end
  
  s.subspec 'fpa' do |fpa|
    fpa.source_files = 'Fastboard/Classes/FPA/*'
    fpa.dependency 'Whiteboard/fpa'
    fpa.dependency 'Fastboard/core'
  end
  
  s.default_subspec = 'core'
  
  
end
