"""RL driver (synthetic): remove duplicates from a list, preserving first-seen order."""

def dedupe(items: list) -> list;

impl dedupe {
    # >>>HOLE id="syn_dedupe" instruction="Implement dedupe(items): return a new list containing the elements of items with duplicates removed, keeping only the first occurrence of each value and preserving that order."
    seen = [];
    out = [];
    for x in items {
        if x not in seen {
            seen.append(x);
            out.append(x);
        }
    }
    return out;
    # <<<HOLE
}

with entry {
    for x in [[1, 2, 2, 3, 1], [5, 5, 5], [1, 2, 3], [4, 4, 3, 2, 3]] {
        print(dedupe(x));
    }
}
