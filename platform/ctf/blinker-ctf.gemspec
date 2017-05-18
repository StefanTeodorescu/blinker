# coding: utf-8
Gem::Specification.new do |s|
  s.name        = 'blinker-ctf'
  s.version     = '3.1.2'
  s.summary     = 'Blinker - CTF backend'
  s.authors     = ['Gábor Szarka']
  s.email       = ['gs509@srcf.net', 'szarkagabor@coralworks.hu']
  s.files       = Dir.glob('{lib,templates}/**/*')
  s.executables = ['blinker-ctf']
  s.license     = 'BSD-3-Clause'
  s.homepage    = 'https://gs509.user.srcf.net/blinker/'

  s.add_dependency 'blinker-framework', '~> 3.0'
  s.add_dependency 'blinker-utils', '~> 0.3', '>= 0.3.2'
  s.add_dependency 'pg', '~> 0.19'
  s.add_dependency 'rest-client', '~> 2.0'

  # readme claims minor versions may break API while in preview
  s.add_dependency 'azure_mgmt_resources', '~> 0.8.0'
  s.add_dependency 'azure_mgmt_dns', '~> 0.8.0'
  s.add_dependency 'azure_mgmt_network', '~> 0.8.0'
end
