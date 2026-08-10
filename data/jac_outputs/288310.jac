"""Parse a tuple string like "(1024;768)" and return strings of the elements."""
def tuple_get(string: str, count: int | None = None) -> list[str] | None {
    if not string {
        return None;
    }
    string = string.strip();
    assert string.startswith("(") and string.endswith(")");
    string = string[1:-1];
    res = [x.strip() for x in string.split(";")];
    if count is not None {
        assert len(res) == count;
    }
    return res;
}