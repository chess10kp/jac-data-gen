"""Apply map_fn on each element in collection, preserving collection type."""
def map_collection(
    collection: list[int | str | float | bool] | tuple[int | str | float | bool, ...] | dict[str, int | str | float | bool] | None | int | str | float | bool,
    map_fn: Callable[[int | str | float | bool], int | str | float | bool]
) -> list[int | str | float | bool] | tuple[int | str | float | bool, ...] | dict[str, int | str | float | bool] | None | int | str | float | bool {
    if collection is None {
        return None;
    }
    if isinstance(collection, (tuple, list)) {
        return `type(collection)(map_fn(x) for x in collection);
    }
    if isinstance(collection, dict) {
        return {k: map_fn(v) for (k, v) in collection.items()};
    }
    return map_fn(collection);
}