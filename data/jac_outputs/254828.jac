"""Corrects rewards to be in the interval 0-1"""
def normalize_rewards(rewards: list[float], reward_is_penalty: bool = False) -> list[float] {
    _rewards = [-r for r in rewards] if reward_is_penalty else rewards;
    rmin = min(_rewards);
    rmax = max(_rewards);
    return [(rwr - rmin) / (rmax - rmin) for rwr in _rewards];
}