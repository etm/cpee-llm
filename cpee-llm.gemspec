Gem::Specification.new do |s|
  s.name             = "cpee-llm"
  s.version          = "1.0.0"
  s.platform         = Gem::Platform::RUBY
  s.license          = "LGPL-3.0"
  s.summary          = "Create CPEE testsets based on user input, current model, and selected LLM."

  s.description      = "see http://cpee.org"

  s.files            = Dir['{server/*,tools/**/*,lib/**/*,ui/**/*}'] + %w(LICENSE Rakefile cpee-llm.gemspec README.md AUTHORS)
  s.require_path     = 'lib'
  s.extra_rdoc_files = ['README.md']
  s.bindir           = 'tools'
  s.executables      = ['cpee-llm']

  s.required_ruby_version = '>=3.4'

  s.authors          = ['Juergen eTM Mangler']

  s.email            = 'juergen.mangler@gmail.com'
  s.homepage         = 'http://cpee.org/'

  s.add_runtime_dependency 'riddl', '~> 1.0'
  s.add_runtime_dependency 'json', '~> 2.10'
  s.add_runtime_dependency 'xml-smart', '~> 0.4'
  s.add_runtime_dependency 'typhoeus', '~> 1.4'
  s.add_runtime_dependency 'llm', '~> 0.7'
end
