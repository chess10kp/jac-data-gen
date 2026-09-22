"""Find the smallest shape larger than shape1 that can be broadcast to shape2."""
def compatible_shape(shape1: list[int] | tuple[int, ...], shape2: list[int] | tuple[int, ...]) -> tuple[int, ...] {
    shape = [];
    n = min(len(shape1), len(shape2));
    for i in range(0, n) {
        if shape1[-1 - i] == 1 {
            shape = [1] + shape;
        } else {
            shape = [shape2[-1 - i]] + shape;
        }
    }
    return tuple(shape);
}