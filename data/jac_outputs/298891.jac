glob _DEFAULT_NAMES = ('z', 'y', 'x');

"""Name of each axis."""
def _default_axis_names(n_dims: int) -> tuple[str, ...] {
    return _DEFAULT_NAMES[-n_dims:];
}