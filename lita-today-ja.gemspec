Gem::Specification.new do |spec|
  spec.name          = "lita-today-ja"
  spec.version       = "0.1.1"
  spec.authors       = ["violetyk"]
  spec.email         = ["yuhei.kagaya@gmail.com"]
  spec.description   = "What is today?"
  spec.summary       = "What is today?"
  spec.homepage      = "https://github.com/violetyk/lita-today-ja"
  spec.license       = "MIT"
  spec.metadata      = { "lita_plugin_type" => "handler" }

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "lita", ">= 4.7"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "pry-byebug"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rack-test"
  spec.add_development_dependency "rspec", ">= 3.0.0"

  spec.add_dependency "nokogiri"
  spec.add_dependency "activesupport"
  spec.add_dependency "html2markdown"
end
