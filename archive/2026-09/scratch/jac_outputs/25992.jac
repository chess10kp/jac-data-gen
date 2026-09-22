"""Given a class and a name, apply python name mangling to it."""
def _mangle(cls: type, name: str) -> str {
    f"_{cls.__name__}__{name}"
}