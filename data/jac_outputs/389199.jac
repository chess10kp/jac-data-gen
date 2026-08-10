"""does nothing"""
def noLOG(*args: int | str | float | bool, **kwargs: dict[str, str]) -> int | str | float | bool | None {
    if len(args) > 0 {
        return args[0];
    }
    return None;
}