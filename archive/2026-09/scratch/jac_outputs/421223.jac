"""Access an arbitrary nested part of dictionary x using keylist."""
def deep_access(x: dict, keylist: list) -> int | dict {
    val: int | dict = x;
    for key in keylist {
        val = val.get(key, 0);
    }
    return val;
}