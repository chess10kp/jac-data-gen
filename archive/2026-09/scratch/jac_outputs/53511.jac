"""docstring for"""
def decode_dict(source: str | int | float | bool | bytes | list | set | dict) -> str | int | float | bool | list | dict {
    if `type(source) in [str, int, float, bool] {
        return source as str | int | float | bool;
    }
    if `type(source) == bytes {
        return (source as bytes).decode();
    }
    if `type(source) in [list, set] {
        return [decode_dict(item) for item in source];
    }
    target = {};
    for (key, value) in list((source as dict).items()) {
        key = decode_dict(key);
        value = decode_dict(value);
        target[key] = value;
    }
    return target;
}