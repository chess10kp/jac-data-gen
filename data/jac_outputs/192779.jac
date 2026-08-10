"""Read a key/path from loaded params."""
def params_get(
    path: str,
    params: dict[str, str | int | float | bool | list[str] | dict]
) -> str | int | float | bool | list[str] | dict {
    r: str | int | float | bool | list[str] | dict = params;
    for p in path.split(".") {
        r = r[p];
    }
    return r;
}