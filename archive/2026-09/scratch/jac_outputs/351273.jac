"""Test for coordinate in truncated octahedron grid"""
def tr_oct_coord_test(x: int, y: int, z: int) -> bool {
    return (z % 4 == 0 and x % 4 and y % 4 and (x - y) % 2)
        or (y % 4 == 0 and z % 4 and x % 4 and (z - x) % 2)
        or (x % 4 == 0 and y % 4 and z % 4 and (y - z) % 2);
}