# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module CognitiveCoherence
      module Helpers
        class Proposition
          include Constants

          attr_reader :id, :content, :domain, :acceptance,
                      :positive_constraints, :negative_constraints,
                      :evidence_count, :created_at, :updated_at

          def initialize(content:, domain: :general, acceptance: DEFAULT_ACCEPTANCE)
            @id                  = SecureRandom.uuid
            @content             = content
            @domain              = domain
            @acceptance          = acceptance.clamp(0.0, 1.0)
            @positive_constraints = []
            @negative_constraints = []
            @evidence_count      = 0
            @created_at          = Time.now.utc
            @updated_at          = Time.now.utc
          end

          def state
            if @acceptance >= ACCEPTANCE_THRESHOLD
              :accepted
            elsif @acceptance < (1.0 - ACCEPTANCE_THRESHOLD)
              :rejected
            else
              :undecided
            end
          end

          def accepted?
            state == :accepted
          end

          def rejected?
            state == :rejected
          end

          def undecided?
            state == :undecided
          end

          def add_positive_constraint(proposition_id:)
            return false if @positive_constraints.include?(proposition_id)

            @positive_constraints << proposition_id
            @updated_at = Time.now.utc
            true
          end

          def add_negative_constraint(proposition_id:)
            return false if @negative_constraints.include?(proposition_id)

            @negative_constraints << proposition_id
            @updated_at = Time.now.utc
            true
          end

          def adjust_acceptance(amount:)
            @acceptance = (@acceptance + amount).clamp(0.0, 1.0)
            @updated_at = Time.now.utc
            @acceptance
          end

          def add_evidence
            @evidence_count += 1
            @updated_at = Time.now.utc
            @evidence_count
          end

          def to_h
            {
              id:                   @id,
              content:              @content,
              domain:               @domain,
              acceptance:           @acceptance,
              state:                state,
              positive_constraints: @positive_constraints.dup,
              negative_constraints: @negative_constraints.dup,
              evidence_count:       @evidence_count,
              created_at:           @created_at,
              updated_at:           @updated_at
            }
          end
        end
      end
    end
  end
end
