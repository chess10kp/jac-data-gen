"""Slice until double hyphen."""
def _until_dh(splited: list[str]) -> tuple[list[str], int] {
    i = 0;
    for (i, s) in enumerate(splited) {
        if s == "--" {
            return (splited[:i], i + 1);
        } elif s.startswith("--") {
            return (splited[:i], i);
        }
    }
    return (splited[:], i + 1);
}