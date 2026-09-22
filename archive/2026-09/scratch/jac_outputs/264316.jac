"""Compute the recall in a zero safe way."""
def recall(overlap_count: int, gold_count: int) -> float {
    if gold_count == 0 {
        return 0.0;
    }
    return overlap_count / float(gold_count);
}