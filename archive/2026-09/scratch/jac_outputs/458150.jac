"""Parse arguments with support for conversion to None."""
def _parse_none(arg: str, fn: object = None) -> str | object | None {
    if arg.lower() in ("none", "0") {
        return None;
    }
    return arg if fn is None else fn(arg);
}