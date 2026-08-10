"""Create formatted string for requested keys if non-null in entity."""
def _create_keys_string(entity: dict[str, str | int | bool | None], keys: tuple[str, ...]) -> str {
    nonnull_keys = [
        f"{key}:${key}"
        for key in keys
        if entity.get(key)
    ];
    return ', '.join(nonnull_keys);
}