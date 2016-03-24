Pod::Spec.new do |s|
  s.name         = "Phonograph"
  s.version      = "0.0.1"
  s.summary      = "Audio Queue Services with Swift"

  s.homepage     = "https://github.com/yarrcc/Phonograph"
  s.license      = { :type => "MIT", :text => "Copyright 2016 Yarr! All Rights Reserved." }
  s.author       = { "Andrey Panchenko" => "asfdfdfd@asfdfdfd.com" }

  s.source       = { :git => "git@github.com:yarrcc/Phonograph.git" }

  s.platform     = :ios, '8.0'
  s.requires_arc = true
       
  s.source_files = "Phonograph/*.swift"

  s.frameworks = "AudioToolbox"
end