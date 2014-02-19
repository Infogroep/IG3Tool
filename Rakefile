require 'rubygems'
Gem::manage_gems
require 'rake/gempackagetask'

spec = Gem::Specification.new do |s| 
	s.name = "ig3tool"
	s.rubyforge_project = "ig3tool"
	s.version = "0.6.1"
	s.author = "Kevin Pinte, Dries Harnie, Lode Hoste"
	s.email = "igtool@infogroep.be"
	s.homepage = "http://infogroep.be"
	s.platform = Gem::Platform::RUBY
	s.summary = "gtk ig3tool client"
	s.files = FileList["{lib,bin}/**", "lib/**/*"].to_a
	s.require_paths << "lib"
	s.require_paths << "lib/ui"
	s.bindir = 'bin'
	s.executables << 'ig3tool'
	s.default_executable = 'ig3tool'
	s.has_rdoc = false
	s.add_dependency("ig3client", ">= 0.6.1")
end

Rake::GemPackageTask.new(spec) do |pkg|
	    pkg.need_tar = true
end

task :default => "pkg/#{spec.name}-#{spec.version}.gem" do
	    puts "generated latest version"
end
