# frozen_string_literal: true

module Legion
  module Extensions
    module CognitiveCoherence
      module Helpers
        class CoherenceEngine
          include Constants

          attr_reader :propositions, :history

          def initialize
            @propositions = {}
            @history      = []
          end

          def add_proposition(content:, domain: :general, acceptance: DEFAULT_ACCEPTANCE)
            return nil if @propositions.size >= MAX_PROPOSITIONS

            prop = Proposition.new(content: content, domain: domain, acceptance: acceptance)
            @propositions[prop.id] = prop
            record_history(:add_proposition, { id: prop.id, domain: domain })
            prop.id
          end

          def add_constraint(prop_a_id:, prop_b_id:, constraint_type:, positive: true)
            prop_a = @propositions[prop_a_id]
            prop_b = @propositions[prop_b_id]
            return { success: false, reason: :proposition_not_found } unless prop_a && prop_b

            unless CONSTRAINT_TYPES.include?(constraint_type)
              return { success: false,
                       reason:  :invalid_constraint_type }
            end

            if positive
              prop_a.add_positive_constraint(proposition_id: prop_b_id)
              prop_b.add_positive_constraint(proposition_id: prop_a_id)
            else
              prop_a.add_negative_constraint(proposition_id: prop_b_id)
              prop_b.add_negative_constraint(proposition_id: prop_a_id)
            end

            record_history(:add_constraint,
                           { prop_a: prop_a_id, prop_b: prop_b_id, type: constraint_type, positive: positive })
            { success: true, constraint_type: constraint_type, positive: positive }
          end

          def compute_coherence(proposition_id:)
            prop = @propositions[proposition_id]
            return 0.0 unless prop

            positive_sum = prop.positive_constraints.sum do |pid|
              neighbor = @propositions[pid]
              neighbor ? neighbor.acceptance * COHERENCE_WEIGHT : 0.0
            end

            negative_sum = prop.negative_constraints.sum do |pid|
              neighbor = @propositions[pid]
              neighbor ? neighbor.acceptance * INCOHERENCE_PENALTY : 0.0
            end

            (prop.acceptance + positive_sum - negative_sum).clamp(0.0, 1.0)
          end

          def maximize_coherence
            return { success: true, iterations: 0, proposition_count: 0 } if @propositions.empty?

            @propositions.each_value { |prop| adjust_proposition(prop) }

            record_history(:maximize_coherence, { overall: overall_coherence })
            {
              success:           true,
              iterations:        1,
              proposition_count: @propositions.size,
              overall_coherence: overall_coherence
            }
          end

          def overall_coherence
            return 0.0 if @propositions.empty?

            total = @propositions.values.sum { |prop| compute_coherence(proposition_id: prop.id) }
            total / @propositions.size
          end

          def coherence_label
            val = overall_coherence
            COHERENCE_LABELS.find { |range, _| range.cover?(val) }&.last || :unknown
          end

          def find_contradictions
            accepted = @propositions.values.select(&:accepted?)
            pairs    = []
            accepted.each { |prop| collect_contradiction_pairs(prop, pairs) }
            pairs
          end

          def partition
            result = { accepted: [], rejected: [], undecided: [] }
            @propositions.each_value { |prop| result[prop.state] << prop.to_h }
            result
          end

          def by_domain(domain:)
            @propositions.values.select { |prop| prop.domain == domain }.map(&:to_h)
          end

          def decay_all
            count = 0
            @propositions.each_value do |prop|
              next if prop.acceptance == DEFAULT_ACCEPTANCE

              delta = (DEFAULT_ACCEPTANCE - prop.acceptance) * DECAY_RATE
              prop.adjust_acceptance(amount: delta) unless delta.abs < 0.0001
              count += 1
            end
            { success: true, decayed_count: count }
          end

          def to_h
            {
              proposition_count: @propositions.size,
              overall_coherence: overall_coherence,
              coherence_label:   coherence_label,
              partition:         partition,
              history_size:      @history.size
            }
          end

          private

          def adjust_proposition(prop)
            positive_pull = prop.positive_constraints.sum do |pid|
              neighbor = @propositions[pid]
              neighbor ? neighbor.acceptance * COHERENCE_WEIGHT : 0.0
            end

            negative_push = prop.negative_constraints.sum do |pid|
              neighbor = @propositions[pid]
              neighbor ? neighbor.acceptance * INCOHERENCE_PENALTY : 0.0
            end

            delta = positive_pull - negative_push
            prop.adjust_acceptance(amount: delta) unless delta.abs < 0.001
          end

          def collect_contradiction_pairs(prop, pairs)
            prop.negative_constraints.each do |neg_id|
              neighbor = @propositions[neg_id]
              next unless neighbor&.accepted?
              next if pairs.any? { |pair| pair[:prop_b] == prop.id && pair[:prop_a] == neg_id }

              pairs << { prop_a: prop.id, prop_b: neg_id }
            end
          end

          def record_history(event, data)
            @history << { event: event, data: data, at: Time.now.utc }
            @history.shift while @history.size > MAX_HISTORY
          end
        end
      end
    end
  end
end
