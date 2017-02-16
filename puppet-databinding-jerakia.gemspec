require 'rake'

Gem::Specification.new do |s|
  s.name       = 'puppet-databinding-jerakiaserver'
  s.version    = '0.2.0'
  s.date       = %x{ /bin/date '+%Y-%m-%d' }
  s.summary    = 'Puppet databding for Jerakia Server'
  s.description    = 'Puppet databinding for Jerakia Server using the Jerakia client libraries'
  s.authors     = [ 'Craig Dunn' ]
  s.files       = [ Rake::FileList["lib/**/*"].to_a ].flatten
  s.homepage    = 'http://jerakia.io'
  s.license     = 'Apache 2.0'
  s.add_dependency 'jerakia-client'
end
