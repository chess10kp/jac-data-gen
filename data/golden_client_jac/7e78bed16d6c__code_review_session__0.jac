def risky_operation(fail: bool) -> int {
    if fail {
        raise ValueError("error");
    }
    return 42;
}
def example() -> int {
    result = 0;
    try {
        result = risky_operation(False);
    } except ValueError {
        result = -1;
    }
    return result;
}
