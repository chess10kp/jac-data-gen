"""Parse tile strings."""
def sh_parse_tile(s: str) -> list[int] {
    return [max(min(int(token), 63), 0) for token in s.split(" ")];
}