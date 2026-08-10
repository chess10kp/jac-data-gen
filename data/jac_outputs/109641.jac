"""check the shape param to match the numpy style inside the graph"""
def _check_shape_compile(shape: int | tuple[int, ...] | list[int]) -> tuple[int, ...] {
    if not isinstance(shape, (int, tuple, list)) {
        raise TypeError(
            f"only int, tuple and list are allowed for shape, but got {type(shape)}"
        );
    }
    if isinstance(shape, int) {
        shape = (shape,);
    }
    if isinstance(shape, list) {
        shape = tuple(shape);
    }
    return shape;
}