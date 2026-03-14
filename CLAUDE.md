# lex-cognitive-coherence

**Level 3 Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`
- **Grandparent**: `/Users/miverso2/rubymine/legion/CLAUDE.md`

## Purpose

Thagard's coherence theory: constraint satisfaction across beliefs, goals, and evidence for brain-modeled agentic AI. Propositions are added to a network with positive (supporting) or negative (contradicting) constraints between them. The coherence engine maximizes global coherence by iteratively accepting or rejecting propositions based on their constraint relationships.

## Gem Info

- **Gem name**: `lex-cognitive-coherence`
- **Version**: `0.1.0`
- **Module**: `Legion::Extensions::CognitiveCoherence`
- **Ruby**: `>= 3.4`
- **License**: MIT

## File Structure

```
lib/legion/extensions/cognitive_coherence/
  cognitive_coherence.rb
  version.rb
  client.rb
  helpers/
    constants.rb
    coherence_engine.rb
    proposition.rb
  runners/
    cognitive_coherence.rb
```

## Key Constants

From `helpers/constants.rb`:

- `CONSTRAINT_TYPES` — `%i[explanatory deductive analogical perceptual conceptual deliberative]`
- `PROPOSITION_STATES` — `%i[accepted rejected undecided]`
- `MAX_PROPOSITIONS` = `200`, `MAX_CONSTRAINTS` = `500`, `MAX_HISTORY` = `300`
- `DEFAULT_ACCEPTANCE` = `0.5`, `ACCEPTANCE_THRESHOLD` = `0.6`
- `COHERENCE_WEIGHT` = `0.1`, `INCOHERENCE_PENALTY` = `0.15`
- `DECAY_RATE` = `0.01`
- `COHERENCE_LABELS` — `0.8+` = `:highly_coherent`, `0.6` = `:coherent`, `0.4` = `:mixed`, `0.2` = `:incoherent`, below = `:contradictory`

## Runners

All methods in `Runners::CognitiveCoherence`:

- `add_coherence_proposition(content:, domain: :general, acceptance: DEFAULT_ACCEPTANCE)` — adds a proposition; returns `proposition_id`; fails if max reached
- `add_coherence_constraint(prop_a_id:, prop_b_id:, constraint_type:, positive: true)` — adds a constraint between two propositions; validates constraint type
- `compute_proposition_coherence(proposition_id:)` — computes coherence score for a single proposition given its constraints
- `maximize_coherence` — iterates coherence maximization across all propositions; updates acceptance states; returns overall coherence
- `find_contradictions` — returns pairs of propositions with strong negative constraints both currently accepted
- `coherence_partition` — splits propositions into accepted/rejected/undecided with counts
- `update_cognitive_coherence` — runs `maximize_coherence` + `decay_all`; intended as periodic runner
- `cognitive_coherence_stats` — full stats: proposition count, coherence, label, partition counts, contradiction count

## Helpers

- `CoherenceEngine` — stores propositions and constraints. `maximize_coherence` is an iterative constraint-satisfaction pass. `decay_all` reduces acceptance scores of undecided propositions. `find_contradictions` scans for conflict pairs.
- `Proposition` — has `content`, `domain`, `acceptance` (float 0.0-1.0), `state` (`:accepted/:rejected/:undecided`). State derived from acceptance vs `ACCEPTANCE_THRESHOLD`.

## Integration Points

- `lex-cognitive-dissonance-resolution` handles high-tension conflicts between beliefs — coherence is the upstream precondition: dissonance arises when propositions are in negative constraint relationships with high acceptance on both sides.
- `lex-dream` contradiction resolution phase can call `find_contradictions` and feed results to dissonance resolution.
- `lex-tick` can run `maximize_coherence` in the coherence phase to maintain internal consistency across the proposition network.

## Development Notes

- Coherence maximization is iterative constraint satisfaction — not guaranteed to reach global optimum. Results improve with each call to `maximize_coherence`.
- `decay_all` reduces undecided proposition acceptance scores, eventually pushing them to `:rejected`. This models the natural fading of unconfirmed beliefs.
- `find_contradictions` scans `accepted` propositions for pairs with strong negative constraints — these are the active dissonance sources.
- `INCOHERENCE_PENALTY = 0.15` exceeds `COHERENCE_WEIGHT = 0.1` — incoherence is penalized more harshly than coherence is rewarded. Asymmetric design.
