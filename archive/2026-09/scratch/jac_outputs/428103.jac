"""Generate nth string label from a char set s."""
def genLabn(n: int, s: str) -> str {
    l = len(s);
    m = n;
    g = "";
    go = True;
    while go {
        c = m % l;
        g = s[c] + g;
        m = m // l;
        go = m > 0;
        m -= 1;
    }
    return g;
}