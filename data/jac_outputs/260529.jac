"""Returns the accidental string from its index, e.g. 1->#."""
def get_accidental(i: int) -> str {
    s: str = "";
    if (i > 0) {
        s = ("x" * (i // 2)) + ("#" * (i % 2));
    } elif (i < 0) {
        s = "b" * abs(i);
    }
    return s;
}