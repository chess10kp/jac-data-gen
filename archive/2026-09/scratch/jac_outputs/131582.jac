"""Determine if the round is fast or slow.

    :meta private:
    """
def is_fast_round(rnd: int, r_fast: int, r_slow: int) -> bool {
    remainder = rnd % (r_fast + r_slow);
    return ((remainder - r_fast) < 0);
}