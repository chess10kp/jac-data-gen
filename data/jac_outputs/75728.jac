"""variable value is used locally """
def remove_spaces(s: str | None) -> str | None {
    value = s;
    if value is None {
        return None;
    }
    if `type(s) is not str {
        raise TypeError("you messed up");
    }
    if value == "" {
        return "";
    }
    if value[0] != " " {
        rest = remove_spaces(value[1:]) as str;
        return value[0] + rest;
    }
    return remove_spaces(value[1:]);
}