Pod::Spec.new do |s|

s.platform = :ios
s.ios.deployment_target = '11'
s.name = "RedSwift"
s.summary = "iOS implementation of Redux."
s.requires_arc = true

s.license = { :type => "MIT", :file => "LICENSE" }
s.homepage = 'https://github.com/kocherovets/RedSwift'
s.author = { 'Dmitry Kocherovets' => 'kocherovets@gmail.com' }

s.version = "1.0.29"
s.source = { :git => 'https://github.com/kocherovets/RedSwift.git', :tag => s.version.to_s  }
s.source_files = "Framework/Sources/**/*.{swift}"

s.swift_version = "5.0"

s.framework = "Foundation"

end
