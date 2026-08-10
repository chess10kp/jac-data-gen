"""Return the nested list shape of a matrix."""
def check_shape(mat: list) -> list[int] {
    shape = [];
    while isinstance(mat, list) {
        shape.append(len(mat));
        mat = mat[0];
    }
    return shape;
}