"""split a dict to 2 dicts."""
def split_kwargs(
    original: dict[str, int | str | float | bool],
    anothers: tuple[str, ...]
) -> tuple[dict[str, int | str | float | bool], dict[str, int | str | float | bool]] {
    new: dict[str, int | str | float | bool] = {};
    for key in anothers {
        try {
            new[key] = original.pop(key);
        } except KeyError {
            ;
        }
    }
    return (original, new);
}