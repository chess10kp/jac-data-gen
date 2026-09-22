"""Convert a path (including volume name) into a filename)."""
def p2f(p: str) -> str {
    i = p.find(":");
    assert i != -1, "Unexpected path format: %s, expecting volume name" % p;
    return p[i + 1:];
}