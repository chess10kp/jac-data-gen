"""Hash and sum each character from string."""
def hash_s(_s: str) -> int {
    s_hashed = 0;
    for _char in _s {
        s_hashed += hash(_char);
    }
    return s_hashed;
}