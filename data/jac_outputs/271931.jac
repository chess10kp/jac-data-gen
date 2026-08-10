"""Set a value in a nested object in base by item sequence."""
def nested_set(base: dict[str | int, int | str | float | bool | dict | list | None], key_list: list[str | int], value: int | str | float | bool | dict | list | None) -> dict[str | int, int | str | float | bool | dict | list | None] {
    for key in key_list[:-1] {
        base = base.setdefault(key, {}) as dict[str | int, int | str | float | bool | dict | list | None];
    }
    base[key_list[-1]] = value;
    return base;
}