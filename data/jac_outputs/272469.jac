""" Converts length 1 lists to singletons """
def _scalarise(value: list[int | float | str | bool] | int | float | str | bool | dict[str, object] | None) -> int | float | str | bool | dict[str, object] | list[int | float | str | bool] | None {
    if isinstance(value, list) and len(value) == 1 {
        return value[0];
    }
    return value;
}