"""Returns True if any dictionary value is encrypted by the AWX encryption algorithm."""
def vars_are_encrypted(vars: dict[str, str | int | float | bool]) -> bool {
    for value in vars.values() {
        if isinstance(value, str) and value.startswith('$encrypted$') {
            return True;
        }
    }
    return False;
}