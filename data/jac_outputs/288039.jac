"""
    Returns `items` that are in `container`.
    """
def select[T](
    items: list[T] | tuple[T, ...],
    container: list[T] | set[T] | tuple[T, ...],
    *,
    ctor: object = None
) -> list[T] | tuple[T, ...] {
    if ctor is None {
        return type(items)(i for i in items if i in container);
    }
    return ctor(i for i in items if i in container) as list[T] | tuple[T, ...];
}