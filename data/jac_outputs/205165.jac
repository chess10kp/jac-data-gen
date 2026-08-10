"""returns coordinates for off diagonal elements"""
def get_matrix_diff_coords(indices: list[int]) -> list[tuple[int, int]] {
    [(i, j) for i in indices for j in indices if i != j]
}