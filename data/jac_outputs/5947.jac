"""Merge two positions and return as a list of strings."""
def join_positions(pos1: str, pos2: str) -> list[str] {
    return [''.join([r1, r2]) for (r1, r2) in zip(pos1, pos2)];
}