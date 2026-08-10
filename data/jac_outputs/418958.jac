"""Update dictionary with the values from other dictionary. Recursively update
    any nested dictionaries if both old and new values are dictionaries."""
def update_nested_dictionary(old: dict[str, object], new: dict[str, object]) -> dict[str, object] {
    for (key, new_value) in new.items() {
        old_value = old.get(key);
        if isinstance(old_value, dict) and isinstance(new_value, dict) {
            old[key] = update_nested_dictionary(old_value, new_value);
        } else {
            old[key] = new_value;
        }
    }
    return old;
}