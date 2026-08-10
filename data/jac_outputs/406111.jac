"""Check whether a nested dict contains a value at the given path."""
def path_exists(source: dict, path: str, separator: str = '/') -> bool {
    if path == separator and isinstance(source, dict) {
        return True;
    }
    parts = path.strip(separator).split(separator);
    if not parts {
        return False;
    }
    current = source;
    for part in parts {
        if not isinstance(current, dict) {
            return False;
        }
        if part not in current {
            return False;
        }
        current = current[part];
    }
    return True;
}