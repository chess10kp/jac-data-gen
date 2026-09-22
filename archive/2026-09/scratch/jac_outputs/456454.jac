"""Must be a non-empty non-blank string"""
def non_empty_string(value: str) -> bool {
    return bool(value) and bool(value.strip());
}