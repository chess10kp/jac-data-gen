"""Old style model is stored with all names of parameters share common prefix 'module."""
def remove_prefix(state_dict: dict[str, object], prefix: str) -> dict[str, object] {
    def f(x: str) -> str {
        return x.split(prefix, 1)[-1] if x.startswith(prefix) else x;
    }
    return {f(key): value for (key, value) in state_dict.items()};
}