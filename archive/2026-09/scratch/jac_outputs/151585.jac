"""Merge command state with keyword arguments.

Command state takes precedence over any keyword argument."""
def full_kwargs(state: dict[str, str | int | float | bool] | None, kwargs: dict[str, str | int | float | bool]) -> dict[str, str | int | float | bool] {
    if state is not None {
        full = kwargs.copy();
        full.update(state);
    } else {
        full = kwargs;
    }
    return full;
}