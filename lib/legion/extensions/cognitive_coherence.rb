# frozen_string_literal: true

require 'legion/extensions/cognitive_coherence/version'
require 'legion/extensions/cognitive_coherence/helpers/constants'
require 'legion/extensions/cognitive_coherence/helpers/proposition'
require 'legion/extensions/cognitive_coherence/helpers/coherence_engine'
require 'legion/extensions/cognitive_coherence/runners/cognitive_coherence'

module Legion
  module Extensions
    module CognitiveCoherence
      extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core
    end
  end
end
