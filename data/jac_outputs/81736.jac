"""Return the dict value for the given ordered keys."""
def safe_get(dct: dict, *keys: str | int, **kwargs: dict[str, str | list | dict | None]) -> str | list | dict | None {
    default_value = kwargs.get("default");
    for key in keys {
        try {
            dct = dct[key];
        } except (KeyError, IndexError) {
            return default_value;
        }
    }
    return dct;
}