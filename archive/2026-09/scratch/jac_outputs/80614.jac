"""Any single key."""
def any_key(m: dict[int, int | str | float] | list[int | str | float]) -> str {
    str(m[0])
}