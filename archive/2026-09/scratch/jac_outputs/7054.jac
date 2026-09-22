"""get matmul shape"""
def caculate_matmul_shape(
    matrix_A_dim: int, matrix_G_dim: int, split_dim: int
) -> tuple[tuple[int, int, int, int], tuple[int, int, int]] {
    split_dimA = split_dim;
    split_dimG = split_dim;
    if matrix_A_dim % split_dim == 0 {
        batch_w = matrix_A_dim // split_dim;
    } elif matrix_A_dim < split_dim {
        batch_w = 1;
        split_dimA = matrix_A_dim;
    } else {
        batch_w = matrix_A_dim // split_dim + 1;
    }
    if matrix_G_dim % split_dim == 0 {
        batch_h = matrix_G_dim // split_dim;
    } elif matrix_G_dim < split_dim {
        batch_h = 1;
        split_dimG = matrix_G_dim;
    } else {
        batch_h = matrix_G_dim // split_dim + 1;
    }
    matrix_A_shape = (batch_h, batch_w, split_dimA, split_dimA);
    matrix_G_shape = (batch_h, split_dimG, split_dimG);
    return (matrix_A_shape, matrix_G_shape);
}