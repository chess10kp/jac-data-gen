""" Calculates the delta between two timestamps.

  """
def _CalcDelta(from_ts: tuple[int, int], to_ts: tuple[int, int]) -> float {
    return (to_ts[0] - from_ts[0]) + (to_ts[1] - from_ts[1]) / 1000000.0;
}