"""Extract text enclosed between left and right markers."""
def lr_mark(line: str, lmark: str, rmark: str) -> str {
    lidx = line.find(lmark);
    assert lidx != -1;
    ridx = line.find(rmark);
    assert ridx != -1;
    return line[(lidx + 1):ridx];
}