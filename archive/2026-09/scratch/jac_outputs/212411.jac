"""Return the sum of cubes for a 1-D input matrix."""
def cubeEach(input_matrix: list[int]) -> int {
    return sum((i ** 3) for i in input_matrix);
}