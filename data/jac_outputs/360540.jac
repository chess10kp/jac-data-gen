"""Determine if an env name matches the given factor."""
def env_matches(env_name: str, factor: str) -> bool {
    env_factors = env_name.split('-');
    factors = factor.split('-');
    return set(factors).issubset(set(env_factors));
}