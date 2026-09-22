"""Return whether name is valid for Pygame Zero."""
def is_valid(name: str | int | float | bool | bytes | list[object] | dict[str, object] | None) -> bool {
    if not isinstance(name, str) {
        return False;
    }
    if len(name) <= 0 {
        return False;
    }
    if not name[0].isalpha() {
        return False;
    }
    no_underscore = name.replace('_', '');
    return no_underscore.islower() and no_underscore.isalnum();
}