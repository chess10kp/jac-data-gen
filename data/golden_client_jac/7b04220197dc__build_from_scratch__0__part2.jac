def letter_counts(s: str) -> str {
    counts = {};
    order = [];
    for c in s {
        if c in counts {
            counts[c] += 1;
        } else {
            counts[c] = 1;
            order.append(c);
        }
    }
    parts = [];
    for c in order {
        parts.append(f"{c}:{counts[c]}");
    }
    return ",".join(parts);
}

with entry {
    for x in ["aabbc", "hello", "abc", "zzz"] {
        print(letter_counts(x));
    }
}
