require 'rubygems'
require 'spec/version'
require 'spec/rake/spectask'

Spec::Rake::SpecTask.new('specs') do |t|
   t.spec_files = FileList['spec/**/*.rb']
   t.rcov = false
   t.rcov_opts = ['--exclude', 'spec']
   t.verbose = true
end
