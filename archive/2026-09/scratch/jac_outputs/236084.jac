"""Function replacement for if-else to use in expressions."""
def cond[T](predicate: bool, consequence: T, alternative: T | None = None) -> T | None {
    if predicate {
        return consequence;
    }
    return alternative;
}