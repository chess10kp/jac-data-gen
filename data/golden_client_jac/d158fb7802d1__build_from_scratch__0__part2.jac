def most_common_word(s: str) -> str {
    counts = {};
    order = [];
    for w in s.split() {
        if w in counts {
            counts[w] += 1;
        } else {
            counts[w] = 1;
            order.append(w);
        }
    }
    best = order[0];
    for w in order {
        if counts[w] > counts[best] {
            best = w;
        }
    }
    return best;
}

with entry {
    for x in ["a b a c a", "one two two three", "hi", "x y y x x"] {
        print(most_common_word(x));
    }
}
