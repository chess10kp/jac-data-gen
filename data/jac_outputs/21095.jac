"""
    Helper to test the LENGTH|TYPE|ID|VALUE data. It is packed in a dictionary like
    {ID: (VALUE, TYPE)
    """
def compare_ltiv_data(
    expected: dict[str, tuple[str | int, str | int]],
    actual: dict[str, tuple[str | int, str | int]]
) -> bool {
    for (k, val) in expected.items() {
        actual_v = actual.pop(k);
        if not (actual_v[0] == val[0] and actual_v[1] == val[1]) {
            return False;
        }
    }
    return actual == {};
}