"""
Returns Scott's factor for KDE approximation.
"""
def scott(n: int, ess: float) -> float {
    1.059 * ess ** (-1 / (n + 4))
}