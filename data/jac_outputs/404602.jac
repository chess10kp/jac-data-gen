"""Return a mapping from activity pairs to follow frequency at a given distance."""
def follows(trace: tuple, distance: int = 1) -> dict[tuple, int] {
    if not isinstance(trace, tuple) {
        raise ValueError("Trace has to be a tuple of activities.");
    }
    if not float(distance).is_integer() {
        raise ValueError("Distance has to be an integer.");
    }
    if not distance >= 1 {
        raise ValueError("Distance has to be greater or equal to 1.");
    }
    pairs = dict();
    for i in range(len(trace) - distance) {
        ai = trace[i];
        aj = trace[i + distance];
        if (ai, aj) not in pairs {
            pairs[(ai, aj)] = 0;
        }
        pairs[(ai, aj)] += 1;
    }
    return pairs;
}