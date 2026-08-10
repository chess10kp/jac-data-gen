"""Tries and creates pythonic name from c names."""
def pythonic(name: object) -> str {
    name = str(name);
    to_lower = lambda (x: str) { x if x == x.lower() else "_" + x.lower(); };
    return name[0].lower() + ''.join([to_lower(u) for u in name[1:]]);
}