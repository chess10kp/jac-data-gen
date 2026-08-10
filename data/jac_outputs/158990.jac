"""Return a string: The JSON representation of the object "obj".
    This is a peasant's version, not intentended to be fully JSON
    general."""
def asjson(`obj: str | int | float | bool | list[int | str] | dict[str, str | int | float | bool] | None) -> str {
    return repr(`obj).replace("'", '"');
}