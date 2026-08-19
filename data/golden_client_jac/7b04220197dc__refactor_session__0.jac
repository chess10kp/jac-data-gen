"""RL driver (synthetic): per-character counts formatted in first-seen order."""

def letter_counts(s: str) -> str;

impl letter_counts {
    # >>>HOLE id="syn_letter_counts" instruction="Implement letter_counts(s): count how many times each distinct character appears in s, then return a comma-separated string of 'char:count' entries ordered by each character's first appearance in s (e.g. 'aabbc' -> 'a:2,b:2,c:1')."
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
    # <<<HOLE
}

with entry {
    for x in ["aabbc", "hello", "abc", "zzz"] {
        print(letter_counts(x));
    }
}
