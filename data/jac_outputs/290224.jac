"""Determine the maximum length of a list within a list of lists."""
def max_length(x: list[int] | int, y: list[int] | int) -> int {
    if isinstance(x, list) and isinstance(y, list) {
        return max(len(x), len(y));
    } elif isinstance(x, list) and isinstance(y, int) {
        return max(len(x), y);
    } elif isinstance(x, int) and isinstance(y, list) {
        return max(x, len(y));
    } elif isinstance(x, int) and isinstance(y, int) {
        return max(x, y);
    }
    if not isinstance(x, int) or not isinstance(x, list) {
        raise TypeError("Invalid type: " + str(type(x)));
    }
    if not isinstance(y, int) or not isinstance(y, list) {
        raise TypeError("Invalid type: " + str(type(x)));
    }
    return 0;
}