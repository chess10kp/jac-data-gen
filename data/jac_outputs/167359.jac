"""Returns d when v is empty (string, list, etc) or false."""
def default(v: str | list[str] | bool | int, d: str | list[str] | bool | int) -> str | list[str] | bool | int {
    if not v {
        v = d;
    }
    return v;
}