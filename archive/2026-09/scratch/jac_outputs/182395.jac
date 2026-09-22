"""Checks the identification of the problem."""
def n_undefined(variables_d: dict[str, float], popset: list[str]) -> float {
    n_pop = len(popset);
    return len(variables_d) - (n_pop * (n_pop - 1)) / 2;
}