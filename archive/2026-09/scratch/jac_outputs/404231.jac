"""Return True if fname stringifies to a bracket-enclosed form."""
def is_json(fname: str | int | float | bool | list[int]) -> bool {
    s = str(fname);
    if s and s[0] == "[" and s[-1] == "]" {
        return True;
    }
    return False;
}