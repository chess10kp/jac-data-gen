"""Get the number of rows and columns for the give number of plots.

    Returns how many rows and columns should be used to have the correct
    number of figures available. This doesn't return anything larger than
    3 columns, but the number of rows can be large.
    """
def subplot_dims(n_plots: int) -> tuple[int, int] {
    if n_plots > 9 {
        n_cols = 3;
        n_rows = (1 + n_plots) // n_cols;
    } elif n_plots < 2 {
        n_rows = n_cols = 1;
    } else {
        n_cols = 2;
        n_rows = (1 + n_plots) // n_cols;
    }
    return (n_rows, n_cols);
}