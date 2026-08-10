"""Convert a string to its boolean value."""
def asbool(s: str) -> bool {
    lower = s.lower();
    if lower == 'true' {
        return True;
    } elif lower == 'false' {
        return False;
    } elif s.isdigit() {
        return bool(int(s));
    } else {
        raise ValueError(('must be integer or boolean: %r' % s));
    }
}