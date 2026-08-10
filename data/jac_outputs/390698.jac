""" Calculate the standard deviation of a task. """
def calculate_standard_deviation(pessimistic: int | float, optimistic: int | float) -> float {
    round((pessimistic - optimistic) / 6, 1)
}