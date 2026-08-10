"""Sum integers."""
def add_integers(*args: int) -> int {
    if not len(args) {
        raise TypeError(f"{add_integers.__name__}() requires at least one argument");
    }
    for i in args {
        if not isinstance(i, int) {
            raise TypeError(
                f"Passed argument of type '{type(i).__name__}', but only integers allowed: {i}"
            );
        }
    }
    return sum(args);
}