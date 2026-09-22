"""Swap (token, (ID, URL)) to ((ID, URL), token)."""
def swap(record: tuple[str, tuple[str, str]]) -> tuple[tuple[str, str], str] {
    token = record[0];
    keys = record[1];
    return (keys, token);
}