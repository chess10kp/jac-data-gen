"""Remove namespace, but only if there is a namespace to begin with."""
def ns(s: str) -> str {
    if '}' in s {
        return '}'.join(s.split('}')[1:]);
    }
    return s;
}