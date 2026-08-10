"""
    Takes a step for each solution.
    """
def take_step(solutions: list[list[int]], step: int) -> list[list[int]] {
    return [(solution + [step]) for solution in solutions];
}