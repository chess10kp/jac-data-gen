"""
    Build current config file structure.
    """
def get_type(value: dict[str, object] | object) -> str | dict[str, object] {
    if isinstance(value, dict) {
        return {key: get_type(value[key]) for key in value};
    }
    return str(`type(value));
}