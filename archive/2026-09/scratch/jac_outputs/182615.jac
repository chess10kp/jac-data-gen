"""Look for the first key corresponding to value in dictionary d."""
def find(d: dict[str, str], value: str) -> str | None {
    for (k, v) in d.items() {
        if v == value {
            return k;
        }
    }
}