"""Given a warning object, return only the warning message."""
def custom_formatwarning(msg: str, *_: str | int | type | None) -> str {
    str(msg) + '\n'
}