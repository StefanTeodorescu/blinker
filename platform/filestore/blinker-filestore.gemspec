# coding: utf-8
Gem::Specification.new do |s|
  s.name        = 'blinker-filestore'
  s.version     = '0.3.1'
  s.summary     = 'Blinker - Simple file store'
  s.authors     = ['Gábor Szarka']
  s.email       = ['gs509@srcf.net', 'szarkagabor@coralworks.hu']
  s.files       = Dir.glob('{lib,views}/**/*')
  s.executables = ['blinker-filestore']
  s.license     = 'BSD-3-Clause'
  s.homepage    = 'https://gs509.user.srcf.net/blinker/'

  s.add_dependency 'blinker-utils', '~> 0.2'
  s.add_dependency 'sinatra', '~> 1.4'
  s.add_dependency 'sinatra-contrib', '~> 1.4'
end
