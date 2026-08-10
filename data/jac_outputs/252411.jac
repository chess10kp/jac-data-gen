"""
    Recursively updates nested directories.
    """
def recursive_update(to_update: dict, update: dict) -> dict {
    if update {
        for (key, value) in update.items() {
            if isinstance(value, dict) {
                value = recursive_update(to_update.get(key, {}), value);
            }
            to_update[key] = value;
        }
    }
    return to_update;
}