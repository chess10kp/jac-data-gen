"""RL driver (synthetic): most frequent word, ties broken by first appearance."""

def most_common_word(s: str) -> str;

impl most_common_word {
    # >>>HOLE id="syn_most_common_word" instruction="Implement most_common_word(s): split s on whitespace and return the word with the highest occurrence count. On a tie, return the word that appears earliest in s. Assume s has at least one word."
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
    # <<<HOLE
}

with entry {
    for x in ["a b a c a", "one two two three", "hi", "x y y x x"] {
        print(most_common_word(x));
    }
}
