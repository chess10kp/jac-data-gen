"""Given a value, determine if it is a true-ish value (case-insensitive for strings)."""
def is_true(item: int | str | bool) -> bool {
    tstrings = ['true', 'yes', 'y', 'on', '1'];
    if isinstance(item, str) and item.lower() in tstrings {
        return True;
    } elif isinstance(item, bool) and item is True {
        return True;
    } elif isinstance(item, int) and item == 1 {
        return True;
    } else {
        return False;
    }
}