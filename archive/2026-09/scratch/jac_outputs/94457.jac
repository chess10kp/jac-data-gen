"""
    Calculate the multiplicative modifier for a pokemon's stat.

    Args:
        pokemon (Pokemon): The pokemon for whom we are calculating.
        stat (str): The stat for which we are calculating this for.

    Returns:
        The multiplier to apply to that pokemon's stat.

    """
def calc_boost_factor(pokemon: dict[str, dict[str, int]], stat_name: str) -> float {
    boost = pokemon["boosts"][stat_name];
    return max(2, 2 + boost) / max(2, 2 - boost);
}