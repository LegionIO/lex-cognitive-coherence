# frozen_string_literal: true

module Legion
  module Extensions
    module CognitiveCoherence
      module Runners
        module CognitiveCoherence
          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex)

          def add_coherence_proposition(content:, domain: :general, acceptance: Helpers::Constants::DEFAULT_ACCEPTANCE,
                                        **)
            return { success: false, reason: :missing_content } if content.nil? || content.empty?

            prop_id = engine.add_proposition(content: content, domain: domain, acceptance: acceptance)
            if prop_id
              Legion::Logging.debug "[cognitive_coherence] add_proposition domain=#{domain} id=#{prop_id[0..7]}"
              { success: true, proposition_id: prop_id, domain: domain, acceptance: acceptance }
            else
              Legion::Logging.warn '[cognitive_coherence] add_proposition failed: max propositions reached'
              { success: false, reason: :max_propositions_reached }
            end
          end

          def add_coherence_constraint(prop_a_id:, prop_b_id:, constraint_type:, positive: true, **)
            unless Helpers::Constants::CONSTRAINT_TYPES.include?(constraint_type)
              return { success: false, reason: :invalid_constraint_type,
                       valid_types: Helpers::Constants::CONSTRAINT_TYPES }
            end

            result = engine.add_constraint(
              prop_a_id:       prop_a_id,
              prop_b_id:       prop_b_id,
              constraint_type: constraint_type,
              positive:        positive
            )

            Legion::Logging.debug "[cognitive_coherence] add_constraint type=#{constraint_type} " \
                                  "positive=#{positive} success=#{result[:success]}"
            result
          end

          def compute_proposition_coherence(proposition_id:, **)
            score = engine.compute_coherence(proposition_id: proposition_id)
            prop  = engine.propositions[proposition_id]

            unless prop
              Legion::Logging.debug "[cognitive_coherence] compute_coherence: #{proposition_id[0..7]} not found"
              return { success: false, reason: :not_found }
            end

            Legion::Logging.debug '[cognitive_coherence] compute_coherence ' \
                                  "id=#{proposition_id[0..7]} score=#{score.round(3)}"
            { success: true, proposition_id: proposition_id, coherence_score: score, state: prop.state }
          end

          def maximize_coherence(**)
            result = engine.maximize_coherence
            overall = result[:overall_coherence]&.round(3)
            Legion::Logging.info '[cognitive_coherence] maximize_coherence ' \
                                 "overall=#{overall} props=#{result[:proposition_count]}"
            result
          end

          def find_contradictions(**)
            pairs = engine.find_contradictions
            Legion::Logging.debug "[cognitive_coherence] find_contradictions count=#{pairs.size}"
            { success: true, contradictions: pairs, count: pairs.size }
          end

          def coherence_partition(**)
            result = engine.partition
            totals = result.transform_values(&:size)
            Legion::Logging.debug "[cognitive_coherence] partition accepted=#{totals[:accepted]} " \
                                  "rejected=#{totals[:rejected]} undecided=#{totals[:undecided]}"
            { success: true, partition: result, counts: totals }
          end

          def update_cognitive_coherence(**)
            coherence_result = engine.maximize_coherence
            decay_result     = engine.decay_all

            overall = coherence_result[:overall_coherence]&.round(3)
            Legion::Logging.info "[cognitive_coherence] update overall=#{overall} " \
                                 "decayed=#{decay_result[:decayed_count]}"
            {
              success:           true,
              overall_coherence: coherence_result[:overall_coherence],
              coherence_label:   engine.coherence_label,
              decayed_count:     decay_result[:decayed_count]
            }
          end

          def cognitive_coherence_stats(**)
            part   = engine.partition
            counts = part.transform_values(&:size)
            Legion::Logging.debug "[cognitive_coherence] stats propositions=#{engine.propositions.size} " \
                                  "coherence=#{engine.overall_coherence.round(3)}"
            {
              success:             true,
              proposition_count:   engine.propositions.size,
              overall_coherence:   engine.overall_coherence,
              coherence_label:     engine.coherence_label,
              partition_counts:    counts,
              contradiction_count: engine.find_contradictions.size,
              history_size:        engine.history.size
            }
          end

          private

          def engine
            @engine ||= Helpers::CoherenceEngine.new
          end
        end
      end
    end
  end
end
