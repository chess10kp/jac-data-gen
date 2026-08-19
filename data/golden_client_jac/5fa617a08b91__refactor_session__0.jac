"""RL driver (synthetic): title-case a phrase (first letter of each word upper)."""

def title_case(s: str) -> str;

impl title_case {
    # >>>HOLE id="syn_title_case" instruction="Implement title_case(s): split s on whitespace and, for each word, uppercase its first character and lowercase the rest; join the words back with single spaces and return the result."
    out = [];
    for w in s.split() {
        out.append(w[0].upper() + w[1:].lower());
    }
    return " ".join(out);
    # <<<HOLE
}

with entry {
    for x in ["hello world", "jAC mL studio", "the QUICK brown fox"] {
        print(title_case(x));
    }
}
