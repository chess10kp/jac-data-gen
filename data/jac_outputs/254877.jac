"""Make return JSON object."""
def ret(error_message: str | None = None, **kwargs: int | str | float | bool | None) -> dict[str, int | str | float | bool | None] {
    r = {};
    if error_message is not None {
        r["error"] = error_message;
    }
    r.update(kwargs);
    return r;
}