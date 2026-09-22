"""returns 'val' instead of throwing an exception when parsing fails"""
def try_parse_int(s: str, base: int = 10, val: int | None = None) -> int | None {
    try {
        return int(s, base);
    } except ValueError {
        return val;
    }
}