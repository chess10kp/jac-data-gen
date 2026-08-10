"""Calculation for recall at k."""
def recall_at(targets: list[int | str], scores: list[int | str], k: int) -> float {
    for target in targets {
        if target in scores[:k] {
            return 1.0;
        }
    }
    return 0.0;
}