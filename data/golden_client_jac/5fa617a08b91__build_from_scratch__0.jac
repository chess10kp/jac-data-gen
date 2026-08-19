def title_case(s: str) -> str {
    out = [];
    for w in s.split() {
        out.append(w[0].upper() + w[1:]);
    }
    return " ".join(out);
}
