"""Simple step function."""
def step_function(
    x: float, step_coordinate: float = 0, value_1: float = 0, value_2: float = 1
) -> float {
    value_1 if x < step_coordinate else value_2
}