"""Like filter, but returns a tuple."""
def tfilter(*args: Callable[[int], bool] | list[int] | None, **kwargs: bool) -> tuple[int, ...] {
    return tuple(filter(*args, **kwargs));
}