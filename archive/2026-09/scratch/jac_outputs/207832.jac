"""
Returns a coefficient to convert money from one point in time to
t years in the future, with an annual interest rate of ir. This is
the inverse of future_to_present_value if calculated with the same
rate and number of years.
"""
def present_to_future_value(ir: float, t: int | float) -> float {
    (1 + ir) ** t
}