"""Compute the network's output based on the "time to first spike" of the two output neurons."""
def compute_output(t0: float | None, t1: float | None) -> float {
    if t0 is None or t1 is None {
        return -1.0;
    }
    tf0: float = t0 as float;
    tf1: float = t1 as float;
    diff: float = tf0 - tf1;
    if diff < 0.0 {
        diff = -diff;
    }
    response: float = 1.1 - 0.1 * diff;
    return max(0.0, min(1.0, response));
}