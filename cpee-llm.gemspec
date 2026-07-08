Gem::Specification.new do |s|
  s.name             = "cpee-llm"
  s.version          = "1.0.1"
  s.platform         = Gem::Platform::RUBY
  s.license          = "LGPL-3.0-or-later"
  s.summary          = "CPEE Conversational Agents"

  s.description      = "see http://cpee.org"

  s.files            = Dir['{server/*,tools/**/*,lib/**/*}'] + %w(LICENSE Rakefile cpee-llm.gemspec README.md AUTHORS)
  s.require_path     = 'lib'
  s.extra_rdoc_files = ['README.md']
  s.bindir           = 'tools'
  s.executables      = ['cpee-llm']

  s.required_ruby_version = '>=3.4'

  s.authors          = ['Nataliia Klievtsova', 'Matthias Ehrendorfer', 'Juergen eTM Mangler']

  s.email            = 'n.klievtsova@gmail.com'
  s.homepage         = 'http://github.com/etm/cpee-llm/'

  s.add_runtime_dependency 'riddl', '~> 1.0'
  s.add_runtime_dependency 'json', '~> 2.10'
  s.add_runtime_dependency 'xml-smart', '~> 0.4'
  s.add_runtime_dependency 'typhoeus', '~> 1.4'
  s.add_runtime_dependency 'ruby_llm', '~> 1.15'
  s.add_runtime_dependency 'rag_embeddings', '~> 0'
end
