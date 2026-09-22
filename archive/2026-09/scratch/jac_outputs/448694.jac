"""Recursively update original_dict with new_dict"""
def recursive_update(original_dict: dict[str, object], new_dict: dict[str, object]) -> dict[str, object] {
    for (new_key, new_value) in new_dict.items() {
        if isinstance(new_value, dict) {
            original_dict[new_key] = recursive_update(
                original_dict.get(new_key, {}) as dict[str, object], new_value
            );
        } else {
            original_dict[new_key] = new_value;
        }
    }
    return original_dict;
}