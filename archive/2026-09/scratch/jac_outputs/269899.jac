"""Prepend prefix and sep to every key in dct."""
def add_prefix[V](dct: dict[str, V], prefix: str, sep: str = "/") -> dict[str, V] {
    return {(prefix + sep + key): value for (key, value) in dct.items()};
}