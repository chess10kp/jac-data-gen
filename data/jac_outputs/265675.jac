"""Return True when all arguments share the same length."""
def is_same_len(*args: list[str | int]) -> bool {
    if len(args) == 0 {
        return True;
    }
    len0 = len(args[0]);
    return all(len(x) == len0 for x in args);
}