"""Slugify a string for use in URLs. This mirrors ``nsot.util.slugify()``."""
def slugify(s: str) -> str {
    for char in ['/'] {
        s = s.replace(char, '_');
    }
    return s;
}