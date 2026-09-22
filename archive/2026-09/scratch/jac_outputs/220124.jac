"""Returnthe product of `args`"""
def prod(*args: int) -> int {
    result = 1;
    for e in args {
        result *= e;
    }
    return result;
}