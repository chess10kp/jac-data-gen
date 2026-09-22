"""Read comma-sperated string."""
def parse_commastr(str_comma: str) -> list[int] | None {
    if str_comma == '' {
        return None;
    }
    (a, b) = map(int, str_comma.split(','));
    return [a, b];
}