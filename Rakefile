# -*- coding: utf-8 -*-
require 'rubygems'
require 'spec/version'
require 'spec/rake/spectask'
require 'rake/gempackagetask'

Spec::Rake::SpecTask.new(:spec) do |t|
   t.spec_files = FileList['spec/**/*.rb']
   t.rcov = false
   t.rcov_opts = ['--exclude', 'spec']
   t.verbose = true
end

spec = Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.summary = 'A tool to generate images/videos of user locations based on Apache log files.'
  s.name = 'ip-world-map'
  s.version = '0.0.1'
  s.requirements << 'RMagick'
  s.require_path = 'lib'
  s.bindir = 'bin'
  s.executables = ['ip-world-map']
  s.files = FileList['{lib,spec}/**/*'].to_a +
            ['Rakefile'] + 
            ['resources/maps/earthmap-1920x960.tif']
  s.description = s.summary
  s.author = 'René Scheibe'
  s.email = 'rene.scheibe@gmail.com'
end

Rake::GemPackageTask.new(spec) do |pkg|
    pkg.need_tar = false
end

task :install_gem => :package do
  `sudo gem install pkg/*.gem`
end

task :default => :install_gem

