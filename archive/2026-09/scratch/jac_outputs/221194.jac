"""Splits "foo, bar, baz" into ["foo", "bar", "baz"]."""
def split_scopes(scopes: str) -> list[str] {
    return [s.strip() for s in scopes.split(', ')];
}