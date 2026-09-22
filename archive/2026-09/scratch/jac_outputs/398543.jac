"""Join two unix-style path keys with a separator."""
def join_keys(key1: str, key2: str, sep: str = "/") -> str {
    key1 = key1.rstrip(sep);
    key2 = key2.lstrip(sep);
    return key1 + sep + key2;
}