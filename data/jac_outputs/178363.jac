"""
    unpacks args

    Used by jsonifiers
    """
def unpack_args(args: tuple[int | str | float | bool | list[str] | dict[str, str], dict[str, str]] | int | str | float | bool | list[str] | dict[str, str]) -> tuple[int | str | float | bool | list[str] | dict[str, str], dict[str, str]] {
    if isinstance(args, tuple) {
        return args;
    }
    return (args, {});
}