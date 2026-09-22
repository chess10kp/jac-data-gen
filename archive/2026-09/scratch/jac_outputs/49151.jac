"""clojure.core/update for Python's stateful maps."""
def update[V](m: dict[str, V], k: str, f: Callable[[V], V], *args: object, **kwargs: object) -> dict[str, V] {
    if k in m {
        m[k] = f(m[k], *args, **kwargs);
    }
    return m;
}