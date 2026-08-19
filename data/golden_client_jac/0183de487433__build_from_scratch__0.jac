def initials(name: str) -> str {
    out = "";
    for w in name.split() {
        out += w[0];
    }
    return out;
}
