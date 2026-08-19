def title_case(s: str) -> str {
    out = [];
    for w in s.split() {
        out.append(w[0].upper() + w[1:].lower());
    }
    return " ".join(out);
}

with entry {
    for x in ["hello world", "jAC mL studio", "the QUICK brown fox"] {
        print(title_case(x));
    }
}
