# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cocoapods-multithread-installpod/version'

Gem::Specification.new do |spec|
  spec.name          = "cocoapods-multithread-installpod"
  spec.version       = CocoapodsMultithreadInstallpod::VERSION
  spec.authors       = ["晨燕"]
  spec.email         = ["chenyan.mnn@taobao.com"]
  spec.summary       = "将cocoapods installer过程中download_dependencies改为多线程，提高效率"
  spec.description   = "将cocoapods installer过程中download_dependencies改为20个线程并发，提高pod update的效率"
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = Dir["lib/**/*.rb"]
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "cocoapods"

end
