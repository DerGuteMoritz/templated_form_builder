require 'rubygems'
require 'spec/rake/spectask'

desc "Run all plugin specs"
 Spec::Rake::SpecTask.new(:spec) do |t|
   t.spec_files = FileList['test/rails_root/spec/**/*_spec.rb']
   t.spec_opts = ['--options', 'test/rails_root/spec/spec.opts']
 end
