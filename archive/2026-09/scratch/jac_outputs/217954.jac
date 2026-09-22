"""Return x if it is a list, else return x wrapped in a list."""
def as_list(x: str | int | float | bool | list[str | int | float | bool], length: int = 1) -> list[str | int | float | bool] {
    if not isinstance(x, list) {
        x = length * [x];
    }
    return x;
}