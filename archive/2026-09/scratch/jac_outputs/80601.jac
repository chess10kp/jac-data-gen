"""Get the 3-vector of coordinates from the site index."""
def get_coord(site: int, L: list[int]) -> list[int] {
    x = site // (L[1] * L[2]);
    yz = site % (L[1] * L[2]);
    y = yz // L[2];
    z = yz % L[2];
    return [x, y, z];
}