"""Break str `s` into a list of str."""
def simple(s: str) -> list[str] {
    import string;
    final_toks: list[str] = [];
    punct = string.punctuation as str;
    for w in s.lower().strip().split() {
        final_toks.append(w.strip(punct));
    }
    return final_toks;
}