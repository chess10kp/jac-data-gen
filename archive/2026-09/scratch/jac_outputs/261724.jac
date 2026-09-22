"""Split string and return the selected token; returns "" when out of range."""
def strtoken(st: str, pos: int, sep: str) -> str {
    out = "";
    s = st.split(sep);
    if len(s) >= abs(pos) and pos != 0 {
        if pos > 0 {
            out = s[pos - 1];
        } else {
            out = s[len(s) + pos];
        }
    }
    return out;
}