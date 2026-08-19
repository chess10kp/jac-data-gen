"""RL driver (synthetic): build uppercase initials from a full name."""

def initials(name: str) -> str;

impl initials {
    # >>>HOLE id="syn_initials" instruction="Implement initials(name): split name on whitespace and return the concatenation of the uppercased first character of each word."
    out = "";
    for w in name.split() {
        out += w[0].upper();
    }
    return out;
    # <<<HOLE
}

with entry {
    for x in ["john smith", "ada lovelace", "the quick brown fox", "solo"] {
        print(initials(x));
    }
}
