"""Return duplicate count."""
def duplicate_count(text: str) -> int {
    unique: dict[str, int] = {};
    for elem in text.lower() {
        if elem in unique {
            unique[elem] = unique[elem] + 1;
        } else {
            unique[elem] = 1;
        }
    }
    return len([k for (k, v) in unique.items() if v >= 2]);
}