"""Check shape_y needs to be broadcast to shape_x."""
def check_two_shapes_need_broadcast(shape_x: list[int], shape_y: list[int]) -> bool {
    if `any(j not in (i, 1) for (i, j) in zip(reversed(shape_x), reversed(shape_y))) {
        raise ValueError(f"{shape_y} could not broadcast with {shape_x}.");
    }
    return shape_y != shape_x;
}