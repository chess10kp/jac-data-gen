def letter_counts(s: str) -> str {
    counts = {};
    for c in s {
        counts[c] = counts.get(c, 0) + 1;
    }
    parts = [f"{c}:{counts[c]}" for c in counts];
    return ",".join(parts);
}
