"""
    Using this model because it satisfies some things that should be true in asymptotic limits:

    As the fineness ratio goes to infinity, the drag-divergent Mach should go to 1.

    As the fineness ratio goes to 0, the drag-divergent Mach should go to some reasonable value in the range of 0 to
    1, probably around 0.5? Certainly no more than 0.6, I imagine. (intuition)

    """
def model(fr: float, p: dict[str, float]) -> float {
    return 1 - (p["a"] / (fr + p["b"])) ** p["c"];
}