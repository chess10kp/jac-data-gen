"""Scoring and reward computation services for Trace."""

def compute_style_score(generated: str, user_style_description: str, context: str) -> float
    by llm(
        reason="Score how well the generated text matches the described user style on a scale of 0.0 to 1.0. Consider vocabulary, sentence structure, tone, directness, and overall voice. Return a single float."
    );

def compute_utility_score(generated: str, prompt: str, context: str) -> float
    by llm(
        reason="Score how useful and appropriate the generated text is as a response to the given prompt in the given context. Consider completeness, accuracy, helpfulness, and appropriateness. Return a single float between 0.0 and 1.0."
    );

def compute_composite_reward(
    style_score: float,
    utility_score: float,
    timing_score: float,
    decision_score: float,
    style_weight: float,
    utility_weight: float,
    timing_weight: float,
    decision_weight: float
) -> float {
    total_weight = style_weight + utility_weight + timing_weight + decision_weight;
    if total_weight == 0.0 {
        return 0.0;
    }
    return (
        style_score * style_weight
        + utility_score * utility_weight
        + timing_score * timing_weight
        + decision_score * decision_weight
    ) / total_weight;
}
