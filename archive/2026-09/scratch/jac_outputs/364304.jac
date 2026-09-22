"""Determine the number of leading b's in vector x."""
def head(_b: int, _x: list[int]) -> int {
    _head = 0;
    for i in _x {
        if i == _b {
            _head += 1;
        } else {
            break;
        }
    }
    return _head;
}