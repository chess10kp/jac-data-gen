"""Calculate new minimum dimensions and corresponding scalar."""
def calc_new_dimensions(max_size: int, width: int, height: int) -> tuple[tuple[int, int], float] {
    width_scalar = max_size / width;
    height_scalar = max_size / height;
    best_fit_scalar = min(width_scalar, height_scalar);
    dimensions = (int(width * best_fit_scalar), int(height * best_fit_scalar));
    return (dimensions, best_fit_scalar);
}