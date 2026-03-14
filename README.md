# lex-cognitive-coherence

Thagard's coherence theory for LegionIO: constraint satisfaction across beliefs, goals, and evidence for brain-modeled agentic AI.

## What It Does

Beliefs are not isolated — they support or contradict each other. This extension builds a constraint network of propositions, where positive constraints (explanatory, deductive, analogical, perceptual, conceptual, deliberative) pull propositions toward mutual acceptance, and negative constraints push them apart. The coherence engine runs iterative constraint satisfaction to maximize global coherence, accepting propositions that cohere well with the network and rejecting those that don't.

## Usage

```ruby
client = Legion::Extensions::CognitiveCoherence::Client.new

p1 = client.add_coherence_proposition(content: 'The agent should be transparent', domain: :ethics)
p2 = client.add_coherence_proposition(content: 'Transparency builds trust', domain: :ethics)
p3 = client.add_coherence_proposition(content: 'Transparency risks privacy', domain: :ethics)

client.add_coherence_constraint(
  prop_a_id: p1[:proposition_id],
  prop_b_id: p2[:proposition_id],
  constraint_type: :explanatory,
  positive: true
)

client.add_coherence_constraint(
  prop_a_id: p1[:proposition_id],
  prop_b_id: p3[:proposition_id],
  constraint_type: :deliberative,
  positive: false
)

client.maximize_coherence
client.find_contradictions
client.cognitive_coherence_stats
```

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
