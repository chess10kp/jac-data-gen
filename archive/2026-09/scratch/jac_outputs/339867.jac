"""Set value to value of key if key found in dict, otherwise set value to
    default."""
def get_value[K, V](dict: dict[K, V], key: K, `default: V | None = None) -> V | None {
    return dict[key] if key in dict else `default;
}