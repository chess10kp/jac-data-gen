"""Normalize a value given their max and minimum values of the lists."""
def normalize_from_minmax(v: float, min_v: float, max_v: float) -> float | int {
    if min_v == 0 and max_v == 0 {
        return 0;
    }
    return (v - min_v) / float(max_v - min_v);
}