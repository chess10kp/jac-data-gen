"""Translate field with an old label into (new_label, new_value) tuples."""
def translate_field(
    label: str,
    translator_map: dict[str, list[tuple[str, Callable[..., str | int | float | bool]]]],
    **kwargs: str | int | float | bool
) -> list[tuple[str, str | int | float | bool]] {
    try {
        return [(new_label, map_function(**kwargs)) for (new_label, map_function) in translator_map[label]];
    } except KeyError {
        raise ValueError("Unknown label");
    }
}