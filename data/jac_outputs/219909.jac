"""Little helper function which turns strings to utf-8 encoded bytes"""
def utf(val: object) -> object {
    if isinstance(val, str) {
        return val.encode('utf-8');
    }
    return val;
}