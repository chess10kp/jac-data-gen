"""minimum is reached at s=s_min"""
def objective(s: float, s_min: float = 100) -> float {
    return -0.5 * ((s - s_min) ** 2);
}