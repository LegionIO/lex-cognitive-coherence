# frozen_string_literal: true

require_relative 'lib/legion/extensions/cognitive_coherence/version'

Gem::Specification.new do |spec|
  spec.name          = 'lex-cognitive-coherence'
  spec.version       = Legion::Extensions::CognitiveCoherence::VERSION
  spec.authors       = ['Esity']
  spec.email         = ['matthewdiverson@gmail.com']

  spec.summary       = 'LEX Cognitive Coherence'
  spec.description   = "Thagard's coherence theory: constraint satisfaction across beliefs, " \
                       'goals, and evidence for brain-modeled agentic AI'
  spec.homepage      = 'https://github.com/LegionIO/lex-cognitive-coherence'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.4'

  spec.metadata['homepage_uri']      = spec.homepage
  spec.metadata['source_code_uri']   = 'https://github.com/LegionIO/lex-cognitive-coherence'
  spec.metadata['documentation_uri'] = 'https://github.com/LegionIO/lex-cognitive-coherence'
  spec.metadata['changelog_uri']     = 'https://github.com/LegionIO/lex-cognitive-coherence'
  spec.metadata['bug_tracker_uri']   = 'https://github.com/LegionIO/lex-cognitive-coherence/issues'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir.glob('{lib,spec}/**/*') + %w[lex-cognitive-coherence.gemspec Gemfile]
  end
  spec.require_paths = ['lib']
  spec.add_development_dependency 'legion-gaia'
end
