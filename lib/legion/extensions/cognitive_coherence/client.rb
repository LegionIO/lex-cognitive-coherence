# frozen_string_literal: true

require 'legion/extensions/cognitive_coherence/helpers/constants'
require 'legion/extensions/cognitive_coherence/helpers/proposition'
require 'legion/extensions/cognitive_coherence/helpers/coherence_engine'
require 'legion/extensions/cognitive_coherence/runners/cognitive_coherence'

module Legion
  module Extensions
    module CognitiveCoherence
      class Client
        include Runners::CognitiveCoherence

        def initialize(**)
          @engine = Helpers::CoherenceEngine.new
        end

        private

        attr_reader :engine
      end
    end
  end
end
