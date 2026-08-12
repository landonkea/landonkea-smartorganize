require_relative "lib/smartorganize/version"

Gem::Specification.new do |spec|
  spec.name          = "smartorganize"
  spec.version       = SmartOrganize::VERSION
  spec.authors       = ["landonkea"]
  spec.summary       = "A CLI tool that organizes files in a folder by type, date, or custom rules."
  spec.description   = "Scans a folder, figures out what each file is, and moves it into a categorized subfolder (Documents, Images, Videos, etc.), with dry-run, undo, and stats support."
  spec.homepage      = "https://github.com/landonkea/landonkea-smartorganize"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= #{File.read(File.join(__dir__, ".ruby-version")).strip.split(".")[0..1].join(".")}"

  spec.files         = Dir["lib/**/*.rb"]
  spec.bindir        = "bin"
  spec.executables   = ["smartorganize"]
  spec.require_paths = ["lib"]

  spec.add_development_dependency "minitest", "~> 5.0"
end
