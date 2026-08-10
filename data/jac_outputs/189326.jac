"""Call a function with the supplied arguments, inside a database transaction."""
def call_in_transaction[T](func: Callable[..., T], *args: object, **kwargs: object) -> T {
    return func(*args, **kwargs);
}