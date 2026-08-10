"""Return JSON-serializable key for given arguments."""
def serializable_key(
    *args: str | int | float | bool | None | tuple | list | dict,
    **kwargs: str | int | float | bool | None | tuple | list | dict
) -> str | int | float | bool | None | tuple | list | dict {
    if len(args) == 1 and not kwargs {
        return args[0];
    }
    return str(args) + str(kwargs);
}