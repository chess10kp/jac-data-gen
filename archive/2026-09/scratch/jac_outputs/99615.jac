"""Returns a copy of a dictionary filtered by a collection of keys to keep."""
def filter_dict_keys[K, V](
    orig_dict: dict[K, V],
    keys_to_keep: list[K],
    *,
    optional: bool = False
) -> dict[K, V] {
    {
        key: orig_dict[key]
        for key in keys_to_keep
        if not optional or key in orig_dict
    }
}