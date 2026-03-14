# frozen_string_literal: true

module Legion
  module Extensions
    module CognitiveCoherence
      module Helpers
        module Constants
          MAX_PROPOSITIONS   = 200
          MAX_CONSTRAINTS    = 500
          MAX_HISTORY        = 300
          DEFAULT_ACCEPTANCE = 0.5
          ACCEPTANCE_THRESHOLD = 0.6
          COHERENCE_WEIGHT = 0.1
          INCOHERENCE_PENALTY = 0.15
          DECAY_RATE         = 0.01

          CONSTRAINT_TYPES = %i[explanatory deductive analogical perceptual conceptual deliberative].freeze
          PROPOSITION_STATES = %i[accepted rejected undecided].freeze

          COHERENCE_LABELS = {
            (0.8..)     => :highly_coherent,
            (0.6...0.8) => :coherent,
            (0.4...0.6) => :mixed,
            (0.2...0.4) => :incoherent,
            (..0.2)     => :contradictory
          }.freeze
        end
      end
    end
  end
end
