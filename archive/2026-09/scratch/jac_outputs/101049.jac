"""Convert given row list into dict with column keys"""
def rowdict(columns: list[str], row: list[int | str]) -> dict[str, int | str] {
    robj: dict[str, int | str] = {};
    for (k, v) in zip(columns, row) {
        robj.setdefault(k, v);
    }
    return robj;
}