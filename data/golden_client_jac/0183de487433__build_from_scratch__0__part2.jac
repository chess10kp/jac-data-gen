def initials(name: str) -> str {
    out = "";
    for w in name.split() {
        out += w[0].upper();
    }
    return out;
}

with entry {
    for x in ["john smith", "ada lovelace", "the quick brown fox", "solo"] {
        print(initials(x));
    }
}
