def get_prior_scale(df: float, target_variance: float) -> float {
    target_variance * (df + 2) / df
}