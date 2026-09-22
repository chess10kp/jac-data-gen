"""Returns set of duplicated items from iterable. Item is duplicated if it appears at least two times."""
def get_duplicates(iterable: list[int]) -> set[int] {
    seen = set();
    seen2 = set();
    for item in iterable {
        if item in seen {
            seen2.add(item);
        } else {
            seen.add(item);
        }
    }
    return seen2;
}