# coding: utf-8
Gem::Specification.new do |s|
  s.name        = 'blinker-web'
  s.version     = '1.8.1'
  s.summary     = 'Blinker - Web application'
  s.authors     = ['Gábor Szarka']
  s.email       = ['gs509@srcf.net', 'szarkagabor@coralworks.hu']
  s.files       = Dir.glob('{lib,public,views}/**/*')
  s.executables = ['blinker-web']
  s.license     = 'BSD-3-Clause'
  s.homepage    = 'https://gs509.user.srcf.net/blinker/'

  s.add_dependency 'blinker-utils', '~> 0.2'
  s.add_dependency 'sinatra', '~> 1.4'
  s.add_dependency 'sinatra-contrib', '~> 1.4'
  s.add_dependency 'haml', '~> 4.0'
  s.add_dependency 'pony', '~> 1.11'
end
