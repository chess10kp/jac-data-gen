"""Remove all prefixes in the input."""
def remove_prefix(_input: str | dict[str, object] | list[object] | bool | int | float | None, prefix: str) -> str | dict[str, object] | list[object] | bool | int | float | None {
    if not prefix.endswith(":") {
        prefix += ':';
    }
    if not _input {
        return _input;
    }
    if isinstance(_input, str) {
        if _input.startswith(prefix) {
            return _input[len(prefix):];
        }
        return _input;
    }
    if isinstance(_input, dict) {
        new_result: dict[str, object] = {};
        for (k, v) in _input.items() {
            if k.startswith(prefix) {
                new_result[k[len(prefix):]] = remove_prefix(v as str | dict[str, object] | list[object] | bool | int | float | None, prefix);
            } else {
                new_result[k] = remove_prefix(v as str | dict[str, object] | list[object] | bool | int | float | None, prefix);
            }
        }
        return new_result;
    }
    if isinstance(_input, list) {
        return [remove_prefix(item as str | dict[str, object] | list[object] | bool | int | float | None, prefix) for item in _input];
    }
    return _input;
}