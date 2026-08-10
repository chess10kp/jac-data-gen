"""Calculates the number of learner steps to do at step=num_observations."""
def _calculate_num_learner_steps(
    num_observations: int, min_observations: int, observations_per_step: float
) -> int {
    n = num_observations - min_observations;
    if n < 0 {
        return 0;
    }
    if observations_per_step > 1 {
        return int(n % int(observations_per_step) == 0);
    }
    return int(1 / observations_per_step);
}