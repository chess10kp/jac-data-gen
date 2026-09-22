"""Filter check for npy files."""
def is_npy(s: str) -> bool {
    return s.find(".npy") != -1;
}