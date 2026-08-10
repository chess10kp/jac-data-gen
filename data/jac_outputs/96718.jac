"""Get color for forward and reverse reads."""
def get_strand_color(is_rev: int) -> int {
    return 1 if 238 <= is_rev <= 244 else 0;
}