"""Convert an object to string and surround in parenthesis if it contains an operator."""
def _maybe_parenthesise(x: object, convert: type = str) -> str {
    warrenters = '+*/\\-^';
    ret = convert(x);
    if any(w in ret for w in warrenters) {
        return '(' + ret + ')';
    }
    return ret;
}