"""Combine two measurement means using inverse-variance weighting.

    Source: https://en.wikipedia.org/wiki/Inverse-variance_weighting
    """
def combine_two_measurement_mean(
    new_mean: float, prev_mean: float, new_std: float, prev_std: float
) -> float {
    new_w = 1 / (new_std * new_std);
    prev_w = 1 / (prev_std * prev_std);
    return (new_w * new_mean + prev_w * prev_mean) / (new_w + prev_w);
}