"""LLM prompts for the Judge Agent."""

obj JudgeVerdict {
    has verdict: str,
        judge_confidence: int,
        rationale: str,
        condition: str;
}

"""Synthesize a verdict from bull and bear coalition arguments.

Evaluate the bull and bear cases for the given ticker. Weigh evidence quality,
consider confidence scores, and factor in momentum trends across prior runs.

Possible verdicts (pick exactly one):
  conviction buy, buy with conditions, hold,
  avoid with conditions, conviction avoid, split decision, insufficient data

Rules:
  - A high-confidence argument outweighs a low-confidence one, even if the
    low-confidence side sounds more alarming.
  - Momentum matters: if bear signals have been accelerating across runs
    (e.g. weak -> moderate -> strong), that acceleration is itself a risk
    signal independent of current strength.
  - If both sides have weak evidence, prefer 'hold' or 'insufficient data'
    over splitting the difference.
  - The rationale should explain which side made the stronger evidentiary case,
    whether risks cited by the bear are already priced in, and whether the
    bull thesis depends on assumptions that could fail.
  - If the verdict is conditional, specify the condition — what would change
    the ruling (e.g. 'revisit if bear momentum reaches strong for 2 runs').
  - Set condition to empty string if there are no conditions.
"""
def synthesize_verdict(
    ticker: str,
    bull_argument: str,
    bull_confidence: int,
    bear_argument: str,
    bear_confidence: int,
    bull_momentum: str,
    bear_momentum: str
) -> JudgeVerdict by llm();
