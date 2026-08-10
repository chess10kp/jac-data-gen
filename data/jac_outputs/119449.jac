"""Convert coordinates into pygame coordinates (lower-left => top left)."""
def to_pygame(coords: tuple[int, int], height: int = 250) -> tuple[int, int] {
    return (coords[0], height - coords[1]);
}