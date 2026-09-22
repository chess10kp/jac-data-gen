"""Generates a map of vector lengths from the center point to each coordinate."""
def gen_cube_vector(
    x: int,
    y: int,
    z: int,
    x_mult: int = 1,
    y_mult: int = 1,
    z_mult: int = 1
) -> list[list[list[int]]] {
    c_x = (x - 1) / 2.0;
    c_y = (y - 1) / 2.0;
    c_z = (z - 1) / 2.0;
    def vect(_x: int, _y: int, _z: int) -> int {
        return int(max(abs(_x - c_x), abs(_y - c_y), abs(_z - c_z)));
    }
    return [
        [[vect(_x, _y, _z) for _z in range(z)] for _y in range(y)] for _x in range(x)
    ];
}