"""
Find the highest value of i such that total_nobs is greater
than nob_limits[i] and return multiplier_values[i]

This routine is used by the buddy check. It's a bit niche.
"""
def get_threshold_multiplier(
    total_nobs: int, nob_limits: list[int], multiplier_values: list[float]
) -> float {
    assert len(nob_limits) == len(multiplier_values), "length of input lists are different";
    assert min(multiplier_values) > 0, "multiplier value less than zero";
    assert min(nob_limits) == 0, "nob_limit of less than zero given";
    assert nob_limits[0] == 0, "lowest nob_limit not equal to zero";
    if len(nob_limits) > 1 {
        for i in range(1, len(nob_limits)) {
            assert nob_limits[i] > nob_limits[i - 1], "nob_limits not in ascending order";
        }
    }
    multiplier: float = -1.0;
    if total_nobs == 0 {
        multiplier = 4.0;
    }
    for i in range(len(nob_limits)) {
        if total_nobs > nob_limits[i] {
            multiplier = multiplier_values[i];
        }
    }
    assert multiplier > 0, "output multiplier less than or equal to zero ";
    return multiplier;
}