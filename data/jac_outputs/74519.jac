"""Parse input parameters which can be tuples."""
def parse_tuple(my_str: str) -> list[str] {
    for c in (")", "]", "}") {
        my_str = my_str.rstrip(c);
    }
    for c in ("(", "[", "{") {
        my_str = my_str.lstrip(c);
    }
    return [s.lstrip().rstrip() for s in my_str.split(",")];
}