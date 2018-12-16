
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "time_intervals/version"

Gem::Specification.new do |spec|
  spec.name          = "time_intervals"
  spec.version       = TimeIntervals::VERSION
  spec.authors       = ["Alistair McKinnell"]
  spec.email         = ["alistairm@nulogy.com"]

  spec.summary       = "Library for doing operations on collections of time intervals."
  spec.homepage      = "https://github.com/nulogy/time_intervals"
  spec.license       = "MIT"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(/^spec\//) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 12.0"
  spec.add_development_dependency "rspec", "~> 3.8"
end
