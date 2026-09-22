"""Recursively update a dictionary. Taken from jupytext.header."""
def recursive_update(target: dict[str, object], update: dict[str, object]) -> dict[str, object] {
    for key in update {
        value = update[key];
        if value is None {
            target.pop(key, None);
        } elif isinstance(value, dict) {
            target[key] = recursive_update(
                target.get(key, {}) as dict[str, object], value as dict[str, object]
            );
        } else {
            target[key] = value;
        }
    }
    return target;
}