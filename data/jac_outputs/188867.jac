"""Indexes values by func."""
def index_by[K, V](func: Callable[[V], K], values: list[V]) -> dict[K, V] {
    return {func(value): value for value in values};
}