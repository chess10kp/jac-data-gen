"""Returns True is test_val is between a and b"""
def test_if_between(a: int, b: int, test_val: int) -> bool {
    if a < b {
        return a <= test_val <= b;
    }
    return b <= test_val <= a;
}