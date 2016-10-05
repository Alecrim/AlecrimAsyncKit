Pod::Spec.new do |s|

  s.name         = "AlecrimAsyncKit"
  s.version      = "3.0"
  s.summary      = "Bringing async and await to Swift world with some flavouring."
  s.homepage     = "https://github.com/Alecrim/AlecrimAsyncKit"

  s.license      = "MIT"

  s.author             = { "Vanderlei Martinelli" => "vanderlei.martinelli@gmail.com" }
  s.social_media_url   = "https://twitter.com/vmartinelli"

  s.osx.deployment_target     = "10.10"
  s.ios.deployment_target     = "8.0"
  s.watchos.deployment_target = "2.0"
  s.tvos.deployment_target    = "9.0"

  s.source       = { :git => "https://github.com/Alecrim/AlecrimAsyncKit.git", :tag => s.version }

  s.source_files = "Source/**/*.swift"

  s.requires_arc = true

end
