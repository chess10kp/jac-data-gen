"""Recursively get a value from a nested dictionary."""
def get_if_exist(data: dict[str, int | dict[str, int | dict]], keys: list[str]) -> int | dict[str, int | dict] | None {
    if keys[0] not in data {
        return None;
    }
    if len(keys) == 1 {
        return data[keys[0]];
    }
    return get_if_exist(data[keys[0]] as dict[str, int | dict], keys[1:]);
}