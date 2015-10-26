Pod::Spec.new do |s|

  s.name         = "AlecrimAsyncKit"
  s.version      = "2.0"
  s.summary      = "Bringing async and await to Swift world with some flavouring."
  s.homepage     = "https://github.com/Alecrim/AlecrimAsyncKit"

  s.license      = "MIT"

  s.author             = { "Vanderlei Martinelli" => "vanderlei.martinelli@gmail.com" }
  s.social_media_url   = "https://twitter.com/vmartinelli"

  s.ios.deployment_target     = "8.0"
  s.osx.deployment_target     = "10.10"
  s.watchos.deployment_target = "2.0"

  s.source       = { :git => "https://github.com/Alecrim/AlecrimAsyncKit.git", :tag => s.version }

  s.source_files = "Source/**/*.swift"

end
