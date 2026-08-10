"""Safe key based data access for lists and dictionaries."""
def key_safe_data_access(data: list[str] | dict[str, int], key: int | str) -> str | int | None {
    try {
        return data[key] as str | int;
    } except (KeyError, IndexError) {
        return None;
    }
}