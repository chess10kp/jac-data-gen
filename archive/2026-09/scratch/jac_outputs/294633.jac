"""mulipli le vector 3 par une matrice care de 3"""
def product_3x3_vector3(matrix: Any, vector: Any) -> object {
    x = (
        (matrix[0][0] * vector[0])
        + (matrix[1][0] * vector[1])
        + (matrix[2][0] * vector[2])
    );
    y = (
        (matrix[0][1] * vector[0])
        + (matrix[1][1] * vector[1])
        + (matrix[2][1] * vector[2])
    );
    z = (
        (matrix[0][2] * vector[0])
        + (matrix[1][2] * vector[1])
        + (matrix[2][2] * vector[2])
    );
    return [x, y, z];
}