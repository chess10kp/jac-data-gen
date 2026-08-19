def hamming_distance(a: str, b: str) -> int {
    count = 0;
    for (x, y) in zip(a, b) {
        if x != y { count += 1; }
    }
    return count;
}

with entry {
    print(hamming_distance("karolin", "kathrin"));
}
