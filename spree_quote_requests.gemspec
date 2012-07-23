Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'spree_quote_requests'
  s.version     = '0.60.3'
  s.summary     = 'Request for Quote Addition for Spree'
  s.description = 'Request for Quote Addition for Spree'
  s.required_ruby_version = '>= 1.8.7'

  s.author            = 'Mark Linn'
  s.email             = 'marklinn@xwcsolutions.com'
  s.homepage          = 'http://www.xwcsolutions.com'
  # s.rubyforge_project = 'actionmailer'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_path = 'lib'
  s.requirements << 'none'

  s.add_dependency('spree_core', '>= 0.60.3')
end
