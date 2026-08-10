"""Convert v to type t, returning v unchanged on failure."""
def ctype(v: int | str, t: type) -> int | str | list[str] | float {
    try {
        return t(v) or v;
    } except (ValueError, TypeError) {
        return v;
    }
}