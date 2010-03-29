require 'rubygems'  
require 'rake'  
  
begin  
  require 'jeweler'  
  Jeweler::Tasks.new do |gemspec|  
    gemspec.name = "dbdom"  
    gemspec.summary = "exposes a jdbc db via dom"  
    gemspec.description = "exposes a jdbc db via dom"  
    gemspec.email = "aaron.hamid@gmail.com"  
    gemspec.homepage = "http://github.com/ahamid/dbdom"  
    gemspec.authors = ["Aaron Hamid"]  
    gemspec.has_rdoc = false # not yet
#    gemspec.files.exclude 'test.sh'
  end  
  Jeweler::GemcutterTasks.new
rescue LoadError  
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"  
end  
  
Dir["#{File.dirname(__FILE__)}/tasks/*.rake"].sort.each { |ext| load ext }
