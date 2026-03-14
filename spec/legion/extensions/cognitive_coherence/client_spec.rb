# frozen_string_literal: true

require 'legion/extensions/cognitive_coherence/client'

RSpec.describe Legion::Extensions::CognitiveCoherence::Client do
  it 'responds to all runner methods' do
    client = described_class.new
    expect(client).to respond_to(:add_coherence_proposition)
    expect(client).to respond_to(:add_coherence_constraint)
    expect(client).to respond_to(:compute_proposition_coherence)
    expect(client).to respond_to(:maximize_coherence)
    expect(client).to respond_to(:find_contradictions)
    expect(client).to respond_to(:coherence_partition)
    expect(client).to respond_to(:update_cognitive_coherence)
    expect(client).to respond_to(:cognitive_coherence_stats)
  end
end
