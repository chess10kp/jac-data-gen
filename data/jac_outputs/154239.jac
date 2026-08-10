"""
>>> traverse_set({'level': {'one': 1}}, 'level', 'one', 42)
{'level': {'one': 42}}
"""
def traverse_config_set(target: dict[str, dict], *args: str | int) -> dict[str, dict] {
    (path, value) = (args[:-1], args[-1]);
    current: dict = target;
    last: dict = target;
    for level in path {
        if not level in current {
            current[level] = {"arg": None, "config": {}};
        }
        last = current[level];
        current = last["config"];
    }
    last["arg"] = value;
    return target;
}