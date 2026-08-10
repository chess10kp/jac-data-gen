"""Unnest a nested list; return the inner element or the list itself."""
def unnest(tup: list | int | str | float | bool) -> list | int | str | float | bool {
    while True {
        if not isinstance(tup, list) {
            return tup;
        }
        if len(tup) != 1 {
            return tup;
        }
        tup = tup[0];
    }
}