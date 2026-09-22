"""Returns a dict key by it's value, ie get_key_from_value({key: value}, value) returns key"""
def get_key_from_value(haystack: dict[str | int, str], needle: str) -> str | int | None {
    for (k, v) in haystack.items() {
        if v == needle {
            return k;
        }
    }
    return None;
}