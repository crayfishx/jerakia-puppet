require 'rake'

Gem::Specification.new do |s|
  s.name       = 'jerakia-puppet'
  s.version    = '0.4.1'
  s.date       = %x{ /bin/date '+%Y-%m-%d' }
  s.summary    = 'Puppet databding and Hiera 3.x backend for Jerakia Server'
  s.description    = 'Legacy Puppet databinding and hiera 3.x backend for Jerakia Server using the Jerakia client libraries'
  s.authors     = [ 'Craig Dunn' ]
  s.files       = [ Rake::FileList["lib/**/*"].to_a ].flatten
  s.homepage    = 'http://jerakia.io'
  s.license     = 'Apache 2.0'
  s.add_dependency 'jerakia-client'
end
