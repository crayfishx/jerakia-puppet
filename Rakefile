ENV['SPEC_OPTS'] = '--format documentation --color'
require 'rake'
require 'rspec/core/rake_task'

@proj_root = Dir.pwd

task :default do
   load 'jerakia/Rakefile'
   ENV['RUBYLIB'] = "#{@proj_root}/lib:#{@proj_root}/jerakia/lib"
   default_task = Rake::Task[:integration_tests]
   default_task.invoke
end
