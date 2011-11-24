require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  gem.name = "collectsnmp"
  gem.homepage = "http://github.com/aia/collectsnmp"
  gem.license = "GPL"
  gem.summary = %Q{CollectSNMP runs SNMP queries and stores results}
  gem.description = %Q{CollectSNMP is an application that runs Simple Network Management Protocol (SNMP) queries, creates and updates corresponding Round-Robin Database (RRD) files, generates, updates, and indexes DRRAW (http://web.taranis.org/drraw/) graphs, and supports plugin-like extensions that add custom tasks and SNMP data writers}
  gem.email = "artem@veremey.net"
  gem.authors = ["Artem Veremey"]
  gem.add_runtime_dependency 'snmp', '>= 0'
  gem.add_development_dependency 'metric_fu', '>= 0'
  gem.add_development_dependency 'flexmock', '>= 0'
  gem.add_development_dependency 'rcov', '>= 0'
  gem.add_development_dependency 'shoulda', '>= 0'
  gem.files.include 'template/*'
  gem.files.include 'config/*'
end
Jeweler::RubygemsDotOrgTasks.new

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

require 'rcov/rcovtask'
desc "Code coverage brief"
Rcov::RcovTask.new("rcov:brief") do |task|
  task.test_files = FileList['test/**/test_*.rb']
  task.rcov_opts << '--exclude /gems/,/Library/,/usr/,spec,lib/tasks'
end

desc "Code coverage detail"
Rcov::RcovTask.new("rcov:detail") do |task|
  task.test_files = FileList['test/**/test_*.rb']
  task.rcov_opts << '--exclude /gems/,/Library/,/usr/,spec,lib/tasks'
  task.rcov_opts << '--text-coverage'
end

task :default => :test

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "collectsnmp #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('CHANGELOG*')
  rdoc.rdoc_files.include('lib/**/*.rb')
  rdoc.options << '--inline-source'
  rdoc.options << '--line-numbers'
  rdoc.options << '--all'
  rdoc.options << '--fileboxes'
  rdoc.options << '--diagram'
end

require 'metric_fu'
MetricFu::Configuration.run do |config|
  #config.metrics  = [:churn, :saikuro, :stats, :flog, :flay]
  config.metrics  = [:saikuro, :flog, :flay, :rcov, :roodi, :reek]
  #config.graphs   = [:flog, :flay, :stats]
  config.graphs   = [:flog, :flay, :rcov, :roodi, :reek]
  config.rcov[:test_files] = ['test/**/test_*.rb']
end

desc "Clear data files"
task :clobber do
  rm_rf Dir.glob('logs/*')
  rm_rf Dir.glob('data/*')
  rm_rf Dir.glob('data2/*')
  rm_rf Dir.glob('drraw/*')
  mkdir "drraw/saved"
end

desc "Run binary"
task :bin do
  cmd = %(bin/collectsnmp config/collectsnmp.xml)
  system cmd
end
