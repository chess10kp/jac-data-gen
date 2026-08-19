def swapcase(s: str) -> str {
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
}

with entry {
    for x in ["Hello World", "jAC ml", "ABC123xyz", "!?."] {
        print(swapcase(x));
    }
}
