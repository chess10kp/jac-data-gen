"""Return the reversed map from k_map (toggle each 0 to 1 and each 1 to 0)."""
def reverse_map(k_map: list[list[int]]) -> list[list[bool]] {
    return [[not cell for cell in line] for line in k_map];
}