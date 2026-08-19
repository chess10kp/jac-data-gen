"""RL driver (synthetic): swap the case of every alphabetic character in a string."""

def swapcase(s: str) -> str;

impl swapcase {
    # >>>HOLE id="syn_swapcase" instruction="Implement swapcase(s): return s with the case of each alphabetic character flipped (uppercase letters become lowercase and vice versa); leave non-alphabetic characters unchanged. Detect an uppercase letter as one whose lowercase form differs from itself, and a lowercase letter as one whose uppercase form differs from itself."
    out = "";
    for c in s {
        if c != c.lower() {
            out += c.lower();
        } else {
            if c != c.upper() {
                out += c.upper();
            } else {
                out += c;
            }
        }
    }
    return out;
    # <<<HOLE
}

with entry {
    for x in ["Hello World", "jAC ml", "ABC123xyz", "!?."] {
        print(swapcase(x));
    }
}
