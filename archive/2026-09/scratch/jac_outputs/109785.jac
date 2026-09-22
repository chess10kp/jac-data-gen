"""Return % identity for two sequences."""
def compute_percent_id(seq_1: str, seq_2: str) -> float {
    assert len(seq_1) == len(seq_2);
    matches = sum(
        [
            1
            for (c1, c2) in zip(seq_1, seq_2)
            if c1 == c2 and c1 != "N" and c2 != "N" and c1 != "-" and c2 != "-"
        ]
    );
    length = len(seq_1.replace("N", "").replace("-", ""));
    return matches * 100 / length if length != 0 else 0;
}