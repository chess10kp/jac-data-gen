"""
Converts a value triplet to boolean2 values
From a triplet: concentration, decay, threshold
Truth value = conc > threshold/decay
"""
def tuple_to_bool(value: tuple[float, float, float]) -> bool {
    return value[0] > value[2] / value[1];
}