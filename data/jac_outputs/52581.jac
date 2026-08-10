"""Approximation for the expected value of Z_{right}^eF (right elegible first)."""
def func_right_elegible_first(
    k_idx: int,
    k_right: float,
    s_right: float,
    cap_right_closed: int,
    closed_ZG_right: float
) -> float {
    mu = k_idx + 1;
    lamb = mu / 2;
    k_0 = k_right;
    s_0 = s_right;
    kp = cap_right_closed;
    closed_EF_right = (
        k_0 * (kp - (2 * s_0) - 1) * (1 - (1 - k_0 / kp) ** (lamb - s_0))
    ) / 4;
    closed_EF_right = closed_EF_right - (
        kp
        * (1 - k_0 / kp)
        * (
            1
            - (1 + (kp - s_0 - 1) * k_0 / kp)
            * (1 - k_0 / kp) ** ((lamb - s_0) + 1)
        )
    ) / (4 * k_0);
    closed_EF_right = closed_EF_right + closed_ZG_right;
    return closed_EF_right;
}