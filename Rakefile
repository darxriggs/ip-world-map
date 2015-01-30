# -*- coding: utf-8 -*-
require 'rubygems'
require 'rubygems/package_task'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new do |t|
   t.pattern = 'spec/**/*.rb'
   t.rcov = false
   t.rcov_opts = %q[--exclude "spec"]
   t.verbose = true
end

spec = Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.required_ruby_version = '>= 1.8.7'
  s.summary = 'A tool to generate images/videos of user locations based on Apache log files.'
  s.name = 'ip-world-map'
  s.version = '1.0.0'
  s.license = 'GPL-2'
  s.executables = ['ip-world-map']
  s.files = FileList['{lib,spec}/**/*'].to_a +
            ['Rakefile'] +
            ['resources/maps/earthmap-1920x960.tif']
  s.has_rdoc = false
  s.description = s.summary
  s.homepage = 'http://github.com/darxriggs/ip-world-map'
  s.author = 'René Scheibe'
  s.email = 'rene.scheibe@gmail.com'

  s.requirements = ['ImageMagick (used by rmagick)', 'ffmpeg (only for animations)']
  s.add_runtime_dependency('rmagick', '~> 2.13', '>= 2.13.1')
  s.add_development_dependency('rspec', '~> 2.6', '>= 2.6.0')
end

Gem::PackageTask.new(spec) do |pkg|
    pkg.need_tar = false
end

desc 'Install gem locally'
task :install_gem => :package do
  `gem install pkg/*.gem --no-ri --no-rdoc`
end

task :default => :install_gem

