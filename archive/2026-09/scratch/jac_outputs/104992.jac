"""Get the value of a given key in the state."""
def get_value(state: dict[str, object], key: str) -> object | None {
    parts = key.split("/", 1);
    if len(parts) > 1 {
        if parts[0] not in state {
            return None;
        }
        return get_value(state[parts[0]] as dict[str, object], parts[1]);
    }
    if key in state {
        return state[key];
    }
    return None;
}