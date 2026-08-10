"""Return the matrix maximum and the f1/f3 sample values at that position."""
def get_max_val_and_indexes(
    results_matrix: list[list[float]],
    f1_sample_values: list[float],
    f3_sample_values: list[float]
) -> tuple[float, float, float] {
    x = y = len(results_matrix);
    x_coord_of_max = 0;
    y_coord_of_max = 0;
    curr_max = results_matrix[0][0];
    for i in range(x) {
        for j in range(y) {
            if results_matrix[i][j] > curr_max {
                curr_max = results_matrix[i][j];
                x_coord_of_max = i;
                y_coord_of_max = j;
            }
        }
    }
    return (
        curr_max,
        f1_sample_values[x_coord_of_max],
        f3_sample_values[y_coord_of_max]
    );
}