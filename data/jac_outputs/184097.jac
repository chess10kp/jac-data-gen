"""Return overlap of intervals (start1, end1) and (start2, end2)."""
def overlap(start1: float, end1: float, start2: float, end2: float) -> float {
    return max(max(end2 - start1, 0) - max(end2 - end1, 0) - max(start2 - start1, 0), 0);
}