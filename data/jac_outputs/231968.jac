"""
    Return the first element in the iterable
    """
def first[K, V](
    iterable: list[V] | list[tuple[K, V]],
    `default: V | None = None,
    key: K | None = None
) -> V | None {
    if key is None {
        for el in iterable {
            return el;
        }
    } else {
        for (key_, el) in iterable {
            if key == key_ {
                return el;
            }
        }
    }
    return `default;
}