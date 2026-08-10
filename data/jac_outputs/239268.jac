"""Return a tuple(min, max) out of list of unsorted integers."""
def get_min_max(ints: list[int]) -> tuple[int, int] | None {
    if not ints {
        return None;
    }
    min_int = max_int = ints[0];
    for integer in ints {
        if integer > max_int {
            max_int = integer;
        } elif integer < min_int {
            min_int = integer;
        }
    }
    return (min_int, max_int);
}