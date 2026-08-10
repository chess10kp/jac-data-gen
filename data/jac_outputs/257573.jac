def is_wildcard_allowed(san_regexes: list[str]) -> bool {
    if not san_regexes {
        return False;
    }
    for val in san_regexes {
        if not val.startswith('[*a') {
            return False;
        }
    }
    return True;
}