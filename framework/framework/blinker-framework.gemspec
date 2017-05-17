# coding: utf-8
Gem::Specification.new do |s|
  s.name        = 'blinker-framework'
  s.version     = '3.2.2'
  s.summary     = 'Blinker - Challenge generation framework'
  s.authors     = ['Gábor Szarka']
  s.email       = ['gs509@srcf.net', 'szarkagabor@coralworks.hu']
  s.files       = Dir.glob 'lib/**/*'
  s.executables = ['blinker']
  s.license     = 'BSD-3-Clause'
  s.homepage    = 'https://gs509.user.srcf.net/blinker/'

  s.add_dependency 'blinker-utils', '~> 0.3'

  s.add_dependency 'json', '~> 1.8'
  s.add_dependency 'rake', '~> 10.4'
  s.add_dependency 'fpm', '~> 1.6'

  s.add_dependency 'selenium-webdriver', '~> 3.2'
  s.add_dependency 'headless', '~> 2.3'

  s.add_dependency 'rltk', '~> 3.0'
end
