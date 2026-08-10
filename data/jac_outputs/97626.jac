"""Convert an object to boolean."""
def tobool(x: str | bool | int | None) -> bool {
    if isinstance(x, str) {
        if x.lower() in ['true', 'yes', 'y'] {
            return True;
        } elif x.lower() in ['false', 'no', 'n'] {
            return False;
        }
    }
    try {
        return bool(int(x));
    } except (ValueError, TypeError) {
        ;
    }
    raise ValueError(("Unknown boolean specifier: '%s'." % x));
}