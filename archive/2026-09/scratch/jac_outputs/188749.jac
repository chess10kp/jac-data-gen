"""A helper function to wrap a side effect (callee) in an expression."""
def call_and_return[T](callee: callable[[], None], returnee: T) -> T {
    callee();
    return returnee;
}