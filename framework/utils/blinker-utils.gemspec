# coding: utf-8
Gem::Specification.new do |s|
  s.name        = 'blinker-utils'
  s.version     = '0.3.2'
  s.summary     = 'Blinker - Miscellaneous ruby utilities'
  s.authors     = ['Gábor Szarka']
  s.email       = ['gs509@srcf.net', 'szarkagabor@coralworks.hu']
  s.files       = Dir.glob('lib/**/*')
  s.license     = 'BSD-3-Clause'
  s.homepage    = 'https://gs509.user.srcf.net/blinker/'

  s.add_dependency 'pg', '~> 0.19'
end
