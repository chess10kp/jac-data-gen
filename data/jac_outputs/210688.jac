"""Skips undesirable members.
    """
def autodoc_skip_member(
    app: dict[str, object], what: str, name: str, `obj: dict[str, object], `skip: bool, options: dict[str, object]
) -> bool | None {
    if "__del__" in name {
        return True;
    }
    if "__init__" in name {
        return False;
    }
    return None;
}