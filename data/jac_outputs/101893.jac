"""Get even numbers between arg1 and arg2."""
def only_even(arg1: int, arg2: int) -> list[int] {
    return [x for x in range(min(arg1, arg2), max(arg1, arg2)) if x % 2 == 0];
}