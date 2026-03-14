# frozen_string_literal: true

require 'legion/extensions/cognitive_coherence/client'

RSpec.describe Legion::Extensions::CognitiveCoherence::Runners::CognitiveCoherence do
  let(:client) { Legion::Extensions::CognitiveCoherence::Client.new }

  describe '#add_coherence_proposition' do
    it 'adds a proposition and returns its id' do
      result = client.add_coherence_proposition(content: 'The sky is blue', domain: :perception)
      expect(result[:success]).to be true
      expect(result[:proposition_id]).to match(/\A[0-9a-f-]{36}\z/)
      expect(result[:domain]).to eq(:perception)
    end

    it 'uses default acceptance when none provided' do
      result = client.add_coherence_proposition(content: 'Water is wet')
      expect(result[:acceptance]).to eq(Legion::Extensions::CognitiveCoherence::Helpers::Constants::DEFAULT_ACCEPTANCE)
    end

    it 'accepts a custom acceptance value' do
      result = client.add_coherence_proposition(content: 'Fire is hot', acceptance: 0.9)
      expect(result[:acceptance]).to eq(0.9)
    end

    it 'returns failure for empty content' do
      result = client.add_coherence_proposition(content: '')
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:missing_content)
    end

    it 'accepts extra keyword arguments via splat' do
      result = client.add_coherence_proposition(content: 'test', extra_param: 'ignored')
      expect(result[:success]).to be true
    end
  end

  describe '#add_coherence_constraint' do
    let(:prop_a_id) { client.add_coherence_proposition(content: 'A')[:proposition_id] }
    let(:prop_b_id) { client.add_coherence_proposition(content: 'B')[:proposition_id] }

    it 'adds a positive coherence constraint between two propositions' do
      result = client.add_coherence_constraint(
        prop_a_id:       prop_a_id,
        prop_b_id:       prop_b_id,
        constraint_type: :explanatory,
        positive:        true
      )
      expect(result[:success]).to be true
      expect(result[:constraint_type]).to eq(:explanatory)
      expect(result[:positive]).to be true
    end

    it 'adds a negative (incoherence) constraint' do
      result = client.add_coherence_constraint(
        prop_a_id:       prop_a_id,
        prop_b_id:       prop_b_id,
        constraint_type: :deductive,
        positive:        false
      )
      expect(result[:success]).to be true
      expect(result[:positive]).to be false
    end

    it 'rejects invalid constraint types' do
      result = client.add_coherence_constraint(
        prop_a_id:       prop_a_id,
        prop_b_id:       prop_b_id,
        constraint_type: :invalid_type
      )
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:invalid_constraint_type)
    end

    it 'returns failure when proposition not found' do
      result = client.add_coherence_constraint(
        prop_a_id:       'nonexistent-id',
        prop_b_id:       prop_b_id,
        constraint_type: :explanatory
      )
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:proposition_not_found)
    end
  end

  describe '#compute_proposition_coherence' do
    it 'computes coherence score for an existing proposition' do
      result = client.add_coherence_proposition(content: 'test proposition', acceptance: 0.7)
      prop_id = result[:proposition_id]

      coherence = client.compute_proposition_coherence(proposition_id: prop_id)
      expect(coherence[:success]).to be true
      expect(coherence[:coherence_score]).to be_a(Float)
      expect(coherence[:coherence_score]).to be_between(0.0, 1.0)
    end

    it 'returns not_found for missing proposition' do
      result = client.compute_proposition_coherence(proposition_id: 'no-such-id')
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:not_found)
    end

    it 'increases coherence score when positive constraints are linked' do
      prop_a = client.add_coherence_proposition(content: 'A', acceptance: 0.8)[:proposition_id]
      prop_b = client.add_coherence_proposition(content: 'B', acceptance: 0.8)[:proposition_id]

      score_before = client.compute_proposition_coherence(proposition_id: prop_a)[:coherence_score]

      client.add_coherence_constraint(
        prop_a_id:       prop_a,
        prop_b_id:       prop_b,
        constraint_type: :explanatory,
        positive:        true
      )

      score_after = client.compute_proposition_coherence(proposition_id: prop_a)[:coherence_score]
      expect(score_after).to be > score_before
    end

    it 'decreases coherence score when negative constraints are linked' do
      prop_a = client.add_coherence_proposition(content: 'A', acceptance: 0.8)[:proposition_id]
      prop_b = client.add_coherence_proposition(content: 'B', acceptance: 0.9)[:proposition_id]

      score_before = client.compute_proposition_coherence(proposition_id: prop_a)[:coherence_score]

      client.add_coherence_constraint(
        prop_a_id:       prop_a,
        prop_b_id:       prop_b,
        constraint_type: :deductive,
        positive:        false
      )

      score_after = client.compute_proposition_coherence(proposition_id: prop_a)[:coherence_score]
      expect(score_after).to be < score_before
    end
  end

  describe '#maximize_coherence' do
    it 'returns success with iteration info when propositions exist' do
      client.add_coherence_proposition(content: 'p1', acceptance: 0.7)
      client.add_coherence_proposition(content: 'p2', acceptance: 0.3)

      result = client.maximize_coherence
      expect(result[:success]).to be true
      expect(result[:proposition_count]).to eq(2)
      expect(result[:overall_coherence]).to be_a(Float)
    end

    it 'returns success with zero iterations when no propositions' do
      result = client.maximize_coherence
      expect(result[:success]).to be true
      expect(result[:iterations]).to eq(0)
    end

    it 'adjusts propositions toward coherent neighbors' do
      prop_a = client.add_coherence_proposition(content: 'A', acceptance: 0.9)[:proposition_id]
      prop_b = client.add_coherence_proposition(content: 'B', acceptance: 0.1)[:proposition_id]

      client.add_coherence_constraint(
        prop_a_id:       prop_a,
        prop_b_id:       prop_b,
        constraint_type: :explanatory,
        positive:        true
      )

      client.maximize_coherence

      prop_b_coherence = client.compute_proposition_coherence(proposition_id: prop_b)
      expect(prop_b_coherence[:coherence_score]).to be > 0.1
    end
  end

  describe '#find_contradictions' do
    it 'returns empty list when no contradictions exist' do
      client.add_coherence_proposition(content: 'p1', acceptance: 0.8)
      result = client.find_contradictions
      expect(result[:success]).to be true
      expect(result[:contradictions]).to be_empty
      expect(result[:count]).to eq(0)
    end

    it 'detects contradictory accepted propositions' do
      prop_a = client.add_coherence_proposition(content: 'A', acceptance: 0.9)[:proposition_id]
      prop_b = client.add_coherence_proposition(content: 'B', acceptance: 0.9)[:proposition_id]

      client.add_coherence_constraint(
        prop_a_id:       prop_a,
        prop_b_id:       prop_b,
        constraint_type: :deductive,
        positive:        false
      )

      result = client.find_contradictions
      expect(result[:count]).to eq(1)
      expect(result[:contradictions].first).to include(:prop_a, :prop_b)
    end

    it 'does not flag contradictions when one proposition is rejected' do
      prop_a = client.add_coherence_proposition(content: 'A', acceptance: 0.9)[:proposition_id]
      prop_b = client.add_coherence_proposition(content: 'B', acceptance: 0.1)[:proposition_id]

      client.add_coherence_constraint(
        prop_a_id:       prop_a,
        prop_b_id:       prop_b,
        constraint_type: :deductive,
        positive:        false
      )

      result = client.find_contradictions
      expect(result[:count]).to eq(0)
    end
  end

  describe '#coherence_partition' do
    it 'partitions propositions by state' do
      client.add_coherence_proposition(content: 'accepted', acceptance: 0.9)
      client.add_coherence_proposition(content: 'rejected', acceptance: 0.1)
      client.add_coherence_proposition(content: 'undecided', acceptance: 0.5)

      result = client.coherence_partition
      expect(result[:success]).to be true
      expect(result[:counts][:accepted]).to be >= 1
      expect(result[:counts][:rejected]).to be >= 1
      expect(result[:counts][:undecided]).to be >= 1
    end

    it 'returns partition with proposition hashes' do
      client.add_coherence_proposition(content: 'high', acceptance: 0.8)
      result = client.coherence_partition
      expect(result[:partition][:accepted].first).to include(:id, :content, :acceptance, :state)
    end
  end

  describe '#update_cognitive_coherence' do
    it 'runs maximize and decay, returning coherence info' do
      client.add_coherence_proposition(content: 'p1', acceptance: 0.8)
      client.add_coherence_proposition(content: 'p2', acceptance: 0.2)

      result = client.update_cognitive_coherence
      expect(result[:success]).to be true
      expect(result[:overall_coherence]).to be_a(Float)
      expect(result[:coherence_label]).to be_a(Symbol)
      expect(result).to have_key(:decayed_count)
    end
  end

  describe '#cognitive_coherence_stats' do
    it 'returns stats summary' do
      client.add_coherence_proposition(content: 'stat test', acceptance: 0.7)

      result = client.cognitive_coherence_stats
      expect(result[:success]).to be true
      expect(result[:proposition_count]).to eq(1)
      expect(result[:overall_coherence]).to be_a(Float)
      expect(result[:coherence_label]).to be_a(Symbol)
      expect(result[:partition_counts]).to be_a(Hash)
      expect(result[:contradiction_count]).to be_a(Integer)
      expect(result[:history_size]).to be_a(Integer)
    end

    it 'reports zero when no propositions' do
      result = client.cognitive_coherence_stats
      expect(result[:proposition_count]).to eq(0)
      expect(result[:overall_coherence]).to eq(0.0)
    end
  end
end
