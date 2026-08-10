"""
Factor the total count in to the difference of the new value.
E.g. for a value of 100ms with 50 measurements, a new measure of 150ms would add 1 ms to the total
"""
def calc_new_value(old_measure: float, new_measure: float, count: int) -> float {
    return (
        old_measure + old_measure + (new_measure - old_measure) * (1.0 / count)
    ) / 2.0;
}