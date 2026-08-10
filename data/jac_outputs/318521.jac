"""Reads stars from current line and returns the rest of line."""
def read_stars(st: str) -> tuple[int, str] {
    star_num = 0;
    rest = st;
    while rest.startswith('*') {
        star_num += 1;
        rest = rest[1:];
    }
    return (star_num, rest.strip());
}