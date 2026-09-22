"""Calculate posterior probability of association from Bayes factor and prior."""
def calculate_posterior(bayes_factor: float, prior_prob: float) -> float {
    if bayes_factor == float('inf') {
        return 1.0;
    }
    posterior_odds = (bayes_factor * prior_prob) / (1.0 - prior_prob);
    return posterior_odds / (1.0 + posterior_odds);
}