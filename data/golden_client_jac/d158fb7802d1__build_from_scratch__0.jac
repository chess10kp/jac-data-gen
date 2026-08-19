def most_common_word(s: str) -> str {
    counts = {};
    for w in s.split() {
        counts[w] = counts.get(w, 0) + 1;
    }
    best = "";
    for w in counts {
        if best == "" or counts[w] > counts[best] { best = w; }
    }
    return best;
}
