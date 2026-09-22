"""Soundex algorithm for phonetic name matching."""
def soundex(name: str, len: int = 4) -> str {
    digits = "01230120022455012623010202";
    sndx = "";
    fc = "";
    for c in name.upper() {
        if c.isalpha() {
            if not fc {
                fc = c;
            }
            d = digits[ord(c) - ord("A")];
            if not sndx or d != sndx[-1] {
                sndx += d;
            }
        }
    }
    sndx = fc + sndx[1:];
    sndx = sndx.replace("0", "");
    return (sndx + len * "0")[:len];
}