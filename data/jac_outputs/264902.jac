""" Calculate the simple gap penalty multiplier for the column. If the
    sequences are weighted, the gaps, when penalized, are weighted
    accordingly. """
def weighted_gap_penalty(col: list[str], seq_weights: list[float]) -> float {
    if len(seq_weights) != len(col) {
        seq_weights = [1.0] * len(col);
    }
    gap_sum = 0.0;
    for (i, c) in enumerate(col) {
        if c == "-" {
            gap_sum += seq_weights[i];
        }
    }
    return 1 - gap_sum / sum(seq_weights);
}