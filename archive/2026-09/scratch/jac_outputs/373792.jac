"""Return True if there are no duplicates elements in slice s[start:stop]."""
def unique3(s: list[int], start: int, stop: int) -> bool {
    if stop - start <= 0 {
        return True;
    } elif not unique3(s, start, stop - 1) {
        return False;
    } elif not unique3(s, start + 1, stop) {
        return False;
    } else {
        return s[start] != s[stop - 1];
    }
}