"""Returns a dictionary stripped of any keys having values of None."""
def strip_none(dic: dict[str, int | str | float | bool | None]) -> dict[str, int | str | float | bool] {
    return {k: v for (k, v) in dic.items() if v is not None};
}