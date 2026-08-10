"""Determine whether the `action` (0 or 1 corresponding to T0 or T1) is feasible for x. T0 is feasible for `x` iff `x` is even and T1 iff `x` is odd."""
def is_admissible(action: int, x: int) -> bool {
    return x % 2 == action;
}