"""Boolean property."""
def bool_prop(name: str, `node: dict) -> bool | None {
    try {
        return `node.get(name);
    } except KeyError {
        return None;
    }
}